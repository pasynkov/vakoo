_ = require "underscore"
_.string = require "underscore.string"
async = require "async"

class Queue

  constructor: (@name, @concurrency = 1)->

    @logger = new Vakoo.Logger {
      label: "#{_.string.classify @name}Queue"
    }

    unless _app.redis
      @logger.error "Redis is required for queue. Failed initialize"


    @initialize()

  getPathToRewritable: -> _.last __filename.split "src/"

  initialize: =>

    @logger.info "Initialize with concurrency `#{@concurrency}`"

    @channelId = @getChannelId()

    _app.redis.subscribe @channelId, @push

    @queue = async.queue @_invoke, @concurrency

    async.parallel [
      (taskCallback)=>

        _app.redis.list(@getRedisProcessingKey()).each(
          (task, done)=>

            _app.redis.list(@getRedisProcessingKey()).remove task, (err)=>
              return done err if err
              @push task
              done()

          taskCallback
        )

      (taskCallback)=>

        _app.redis.list(@getRedisWaitingKey()).each(
          (task, done)=>
            _app.redis.list(@getRedisWaitingKey()).remove task, (err)=>
              return done err if err
              @push task
              done()
          taskCallback
        )

    ], (err)=>
      if err
        @logger.error "Initialize failed with err: `#{err}`"
      else
        @logger.info "Initialize successfully"


  invoke: (task, callback)=> callback()

  getChannelId: (name = @name)=>

    _app.package.name + "_" + _.first(_app.env.split("_")) + "_queue_" + name

  getRedisWaitingKey: (name = @name)=>

    Queue::getChannelId(name) + "_waiting_tasks"

  getRedisProcessingKey: (name = @name)=>

    Queue::getChannelId(name) + "_processing_tasks"

  fill: ([name]..., task)=>

    name ?= @name

    _app.redis.publish Queue::getChannelId(name), task

  push: (task)=>

    if @isAction task
      @runAction task
      return

    @logger.info "Push task `#{JSON.stringify task}`"

    _app.redis.list(@getRedisWaitingKey()).append task, (err)=>
      if err
        @logger.error "Append to redis failed with err: `#{err}`"
      else
        @queue.push task

  isAction: (task)=>

    _.isObject(task) and task.action and task.action in [SLEEP_ACTION, PAUSE_ACTION, RESUME_ACTION]

  runAction: ({action, arg})=>

    @logger.info "Run action `#{action}`"

    if action is SLEEP_ACTION
      @sleep arg
    else if action is PAUSE_ACTION
      @pause()
    else if action is RESUME_ACTION
      @resume()

  waitingLength: ([name]..., callback)=>

    name ?= @name

    _app.redis.list(Queue::getRedisWaitingKey(name)).length callback

  processingLength: ([name]..., callback)=>

    name ?= @name

    _app.redis.list(Queue::getRedisProcessingKey(name)).length callback

  pause: (name = false)=>

    if name
      return _app.redis.publish Queue::getChannelId(name), Queue::createAction(PAUSE_ACTION)

    if @queue.paused
      @logger.warn "Already paused"
      false
    else
      @logger.info "Pause"
      @queue.pause()
      true

  resume: (name = false)=>

    if name
      return _app.redis.publish Queue::getChannelId(name), Queue::createAction(RESUME_ACTION)

    @logger.info "Resume"
    @queue.resume()

  sleep: ([name]..., seconds)=>

    if name

      return _app.redis.publish Queue::getChannelId(name), Queue::createAction(SLEEP_ACTION, seconds)


    if @pause()
      @logger.info "Sleep for `#{seconds}` seconds"

      setTimeout(
        @resume
        seconds * 1000
      )

  createAction: (action, arg)-> {action, arg}

  _invoke: (task, callback)=>

    _callback = (err)=>
      if err
        @logger.error "Task `#{JSON.stringify(task)}` failed with err: `#{err}`"
      callback()

    @logger.info "Invoke with task `#{JSON.stringify task}`"

    async.series [
      async.apply _app.redis.list(@getRedisWaitingKey()).remove, task
      async.apply _app.redis.list(@getRedisProcessingKey()).append, task
      async.apply @invoke, task
      async.apply _app.redis.list(@getRedisProcessingKey()).remove, task
      async.asyncify => @logger.info "Task successfully completed"
    ], _callback

module.exports = Queue