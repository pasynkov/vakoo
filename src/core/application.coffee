async = require "async"
_ = require "underscore"
_.string = require "underscore.string"


class Application

  constructor: (@env)->

    @logger = new Vakoo.Logger {
      label: "Application"
    }

    @configs = new Vakoo.Configurator @env

    @package = require Vakoo.Static.resolveFromCwd "package.json"

    @name = Vakoo.Utils.fileSlugify @package.name + " " + @env

  initialize: (callback)=>

    @logger.info "Initialize"

    async.waterfall(
      [
        @initializeConfigsAndStorage
        async.apply async.parallel, [
          @invokeInitializers
          @startTimers
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


  startTimers: (callback)=>

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


module.exports = Application