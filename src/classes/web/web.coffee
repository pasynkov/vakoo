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
        @server.start
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
        catch e
          callback e

      else if _.isArray(@config.routes)

        for route in @config.routes

          if (params = @createRouteParamFromArray(route))
            @server.addRoute.apply @server, params

        callback()

      else callback()
    else callback()

  loadControllersRoutes: (callback)=>

    return callback() if @server.hasRoutes()

    for name, Controller of @controllers
      if _.isArray Controller::routes
        for route in Controller::routes
          if (params = @createRouteParamFromArray(route, name))
            @server.addRoute.apply @server, params

    callback()

  createRouteParamFromArray: (route, controller = null)->

    return false unless _.isArray(route)

    method = "*"
    action = null

    if controller

      if route.length is 1
        [path] = route
      else if route.length is 2
        [path, action] = route
      else if route.length is 3
        [method, path, action] = route

    else

      if route.length is 2
        [path, controller] = route
      else if route.length is 3
        [path, controller, action] = route
      else if route.length is 4
        [method, path, controller, action] = route

    unless action
      path += ":action"

    if controller and method and path
      [method, path, controller, action]
    else false





module.exports = Web