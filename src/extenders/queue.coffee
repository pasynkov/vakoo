_ = require "underscore"
_.string = require "underscore.string"
async = require "async"

SLEEP_ACTION = "queue_action_sleep"
PAUSE_ACTION = "queue_action_pause"
RESUME_ACTION = "queue_action_resume"
REMOVE_TASK_ACTION = "queue_action_remove_task"

class Queue

  constructor: (@name, @concurrency = 1)->

    @logger = new Vakoo.Logger {
      label: "#{_.string.classify @name}Queue"
    }

    unless _app.redis
      @logger.error "Redis is required for queue. Failed initialize"
      return

    @idleInterval = setInterval(
      @checkIdle
      60 * 1000
    )

    @initialize()

  getPathToRewritable: -> _.last __filename.split "src/"

  initialize: (callback = ->)=>

    @logger.info "Initialize with concurrency `#{@concurrency}`"

    @channelId = @getChannelId()

    if @seriesPush()
      @logger.info "Start pushQueue"
      @pushQueue = async.queue @applyPush

    _app.redis.subscribe @channelId, @push

    @queue = async.queue @_invoke, @concurrency

    async.each(
      [
        @getRedisProcessingKey()
        @getRedisWaitingKey()
      ]
      @resurrectTasksFromList
      (err)=>
        if err
          @logger.error "Initialize failed with err: `#{err}`"
        else
          @logger.info "Initialize successfully"
        callback err
    )

  resurrectTasksFromList: (listName, callback)=>

    _app.redis.list(listName).each(
      (task, done)=>

        handler = @removeTaskFromWaitList
        if listName is @getRedisProcessingKey()
          handler = @removeTaskFromProcessingList

        async.applyEach [
          handler
          @push
        ], task, done

      callback
    )

  uniqueTasks: -> false

  seriesPush: -> false

  checkIdle: =>

    if @queue.idle()
      @logger.info "Idle ..."


  invoke: (task, callback)=> callback()

  getChannelId: (name = @name)=>

    _app.package.name + "_" + _app.env + "_queue_" + name

  getRedisWaitingKey: (name = @name)=>

    Queue::getChannelId(name) + "_waiting_tasks"

  getRedisProcessingKey: (name = @name)=>

    Queue::getChannelId(name) + "_processing_tasks"

  fill: ([name]..., task)=>

    name ?= @name

    _app.redis.publish Queue::getChannelId(name), task

  applyPush: (task, callback)=>
    console.log "apply push"
    @_push task, callback

  push: (task, callback = ->)=>

    if @seriesPush()
      @pushQueue.push task
      callback()
    else
      @_push task, callback

  _push: (task, callback = ->)=>

    if @isAction task
      @runAction task
      return

    @logger.info "Push task `#{JSON.stringify task}`"

    if @uniqueTasks()

      @logger.info "Checking task existing"

      existing = _.find @queue.tasks, ({data})->
        _.isEqual data, task

      if existing
        @logger.info "Task `#{JSON.stringify(task)}` already in queue, skipping"
        return callback()

    @addTaskToWaitList task, (err)=>
      if err
        @logger.error "Append to redis failed with err: `#{err}`"
      else
        @queue.push task

      callback()

  isAction: (task)=>

    _.isObject(task) and task.action and task.action in [SLEEP_ACTION, PAUSE_ACTION, RESUME_ACTION, REMOVE_TASK_ACTION]

  runAction: ({action, arg})=>

    @logger.info "Run action `#{action}`"

    if action is SLEEP_ACTION
      @sleep arg
    else if action is PAUSE_ACTION
      @pause()
    else if action is RESUME_ACTION
      @resume()
    else if action is REMOVE_TASK_ACTION
      @removeTask arg

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

  getWaitingTasks: ([name]..., callback)=>

    name ?= @name

    _app.redis.list(Queue::getRedisWaitingKey(name)).get callback

  getProcessingTasks: ([name]..., callback)=>

    name ?= @name

    _app.redis.list(Queue::getRedisProcessingKey(name)).get callback

  removeTask: ([name]..., task)=>

    if name
      return _app.redis.publish Queue::getChannelId(name), Queue::createAction(REMOVE_TASK_ACTION, task)

    @logger.info "Removing task `#{JSON.stringify(task)}`"

    @pause()

    async.series [
      async.apply @removeTaskFromAllLists, task
      async.asyncify =>
        @queue.tasks = _.reject @queue.tasks, ({data})->
          _.isEqual data, task
    ], (err)=>
      return @logger.error "Remove task from redis failed with err: `#{err}`" if err

      @resume()


  addTaskToProcessingList: (task, callback)=>

    @addTaskToList @getRedisProcessingKey(), task, callback

  addTaskToWaitList: (task, callback)=>

    @addTaskToList @getRedisWaitingKey(), task, callback

  addTaskToList: (listName, task, callback)=>

    _app.redis.list(listName).append task, (err)=>
      @logCurrentState()
      callback err

  removeTaskFromWaitList: (task, callback)=>

    @removeTaskFromList @getRedisWaitingKey(), task, callback

  removeTaskFromProcessingList: (task, callback)=>

    @removeTaskFromList @getRedisProcessingKey(), task, callback

  removeTaskFromAllLists: (task, callback)=>

    async.applyEach [
      @removeTaskFromProcessingList
      @removeTaskFromWaitList
    ], task, callback

  removeTaskFromList: (listName, task, callback)=>

    _app.redis.list(listName).remove task, (err)=>
      @logCurrentState()
      callback err

  _invoke: (task, callback)=>

    @logger.info "Invoke with task `#{JSON.stringify task}`"

    async.applyEach [
      @removeTaskFromWaitList
      @addTaskToProcessingList
      @invoke
    ], task, (err)=>

      message = "Task `#{JSON.stringify task}` " +
        if err then "failed with err: `#{err}`" else "successfully completed"

      @logger[if err then "error" else "info"] message

      @removeTaskFromProcessingList task, callback

  logCurrentState: (..., callback)=>

    async.parallel {
      processing: @processingLength
      waiting: @waitingLength
    }, (err, {processing, waiting})=>
      if err
        @logger.error err
      else
        @logger.info "Current state: `#{processing}` processing tasks, `#{waiting}` waiting tasks."
      callback?(err)

module.exports = Queue