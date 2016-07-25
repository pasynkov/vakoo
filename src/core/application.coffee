async = require "async"
_ = require "underscore"
_.string = require "underscore.string"


class Application

  constructor: (@env, @context)->

    @logger = new Vakoo.Logger {
      label: "Application"
    }

    @configs = new Vakoo.Configurator @env, @context

    @package = require Vakoo.Static.resolveFromCwd "package.json"

    @name = Vakoo.Utils.fileSlugify @package.name + " " + @env

    Vakoo.Utils.rewriteCoreClasses @logger

  initialize: (callback)=>

    @logger.info "Initialize"

    async.waterfall(
      [
        @initializeConfigsAndStorage
        async.apply async.parallel, [
          @invokeInitializers
          @initializeTimers
          @initializeQueues
        ]
        Vakoo.Utils.asyncSkip
        @initializeWeb
        Vakoo.Utils.asyncLog @logger.info, "Initialized successfully"
      ]
      callback
    )

  initializeConfigsAndStorage: (callback)=>

    async.waterfall(
      [
        @configs.initialize
        @initializeStorage
      ]
      callback
    )


  initializeWeb: (callback)=>

    if not _.isEmpty(@configs.web) and @configs.web.enable isnt false
      @web = new Vakoo.Web @configs.web

      @web.initialize callback

    else callback()

  initializeStorage: (callback)=>

    if not _.isEmpty(@configs.storage) and @configs.storage.enable isnt false
      @storage = new Vakoo.Storage @configs.storage

      @storage.initialize callback

    else callback()

  invokeInitializers: (callback)=>

    if not _.isEmpty @configs.initializers

      async.eachSeries(
        @configs.initializers
        (name, done)=>

          try
            Initializer = require Vakoo.c.PATH_INITIALIZERS + Vakoo.c.PATH_SEPARATOR + name
          catch e
            @logger.error "Initializer `#{name}` failed with err: `#{e.toString()}`"
            return done()

          initializer = new Initializer name

          initializer._invoke done

        callback
      )

    else callback()


  initializeTimers: (callback)=>

    @timers = {}

    if not _.isEmpty @configs.timers

      async.each(
        @configs.timers
        ({file, time}, done)=>

          try
            Timer = require Vakoo.c.PATH_TIMERS + Vakoo.c.PATH_SEPARATOR + file
          catch e
            @logger.error "Timer `#{file}` failed with err: `#{e.toString()}`"
            return done()

          @timers[file] = new Timer file, time

        callback
      )

    else callback()

  initializeQueues: (callback)=>

    @queues = {}

    if not _.isEmpty @configs.queues

      async.eachOf(
        @configs.queues
        (concurrency, file, done)=>

          try
            Queue = require Vakoo.c.PATH_QUEUES + Vakoo.c.PATH_SEPARATOR + file
          catch e
            @logger.error "Queue `#{file}` failed with err: `#{e.toString()}`"
            return done()

          @queues[file] = new Queue file, concurrency

        callback
      )

    else callback()


module.exports = Application