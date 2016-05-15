async = require "async"
_ = require "underscore"

class Web

  constructor: (@config)->

    @logger = new Vakoo.Logger {
      label: "Web"
    }

    @server = new Vakoo.WebServer @config

    @controllers = {}

  initialize: (callback)=>

    async.waterfall(
      [
        @loadControllers
        @loadRoutes
        Vakoo.Utils.asyncLog @logger.info, "Web start at port `#{@server.getPort()}`"
      ]
      callback
    )

  loadControllers: (callback)=>

    async.waterfall(
      [
        async.apply Vakoo.Static.getDirFiles, Vakoo.c.PATH_CONTROLLERS
        async.asyncify (files)-> _.map files, (file)-> file.replace Vakoo.c.EXT_COFFEE, ""
        (files, taskCallback)=>

          @controllers = _.mapObject(
            _.object files, [0..files.length-1]
            (val, key)-> require Vakoo.c.PATH_CONTROLLERS + Vakoo.c.PATH_SEPARATOR + key
          )

          taskCallback()

      ]
      callback
    )

  loadRoutes: (callback)=>

    async.parallel(
      [
        @loadConfigRoutes
        @loadControllersRoutes
      ]
      callback
    )

  loadConfigRoutes: (callback)=>

    if @config.routes
      if @config.routes.file

        try
          Router = require Vakoo.c.PATH_CONFIGS + Vakoo.c.PATH_SEPARATOR + @config.routes.file

          new Router @server

        callback()

      else if _.isArray(@config.routes)

        for route in @config.routes
          if _.isArray(route)
            console.log route


      else callback()
    else callback()

  loadControllersRoutes: (callback)=>



module.exports = Web