Express = require "express"
BodyParser = require "body-parser"
CookieParser = require "cookie-parser"
Compression = require "compression"
createStatic = require "connect-static"
basicAuth = require "basicauth-middleware"

async = require "async"
_ = require "underscore"

class WebServer

  constructor: (@config)->

    @logger = new Vakoo.Logger {
      label: "WebServer"
    }

    @express = Express()

    @addMiddleware Compression()
    @addMiddleware BodyParser.json()
    @addMiddleware BodyParser.text()
    @addMiddleware BodyParser.raw()
    @addMiddleware BodyParser.urlencoded(
      extended: true
    )
    @addMiddleware CookieParser()

    if @config.auth
      @addMiddleware basicAuth(
        @config.auth.username
        @config.auth.password
        @config.auth.message
      )

    @_currentRoutes = []

  hasRoutes: => not _.isEmpty @_currentRoutes

  addMiddleware: ([path]..., middleware)=>

    if path
      @express.use path, middleware
    else
      @express.use middleware

  addRoute: (method, route, controllerName, action = null)->

    if method is "rest"
      return @addRestRoutes route, controllerName, action

    if method is "*"
      method = "all"

    @_currentRoutes.push [method, route, controllerName, action]

    @express[method] route, (req, res)->
      context = new Vakoo.WebContext req, res, controllerName, action
      new _app.web.controllers[controllerName](context)[context.getAction()]()

  addRestRoutes: (route, controllerName, action = null)->

    if route[-1...] is "/"
      route = route[0...-1]

    for method in ["get", "post"]
      do (method)=>
        @_currentRoutes.push [method, route, controllerName, action]
        @express[method] route, (req, res)->
          subAction = if method is "get" then "list" else "create"
          context = new Vakoo.WebContext req, res, controllerName, action, subAction
          new _app.web.controllers[controllerName](context)[context.getAction()]()[context.getSubAction()]()

    for method in ["get", "put", "delete", "patch"]
      do (method)=>
        @_currentRoutes.push [method, route + "/:id", controllerName, action]
        @express[method] route + "/:id", (req, res)=>
          context = new Vakoo.WebContext req, res, controllerName, action, method
          controller = new _app.web.controllers[controllerName](context)
          controllerAction = controller[context.getAction()]()
          if _.isFunction(controllerAction[method])
            controllerAction[method](context.request.params.id)
          else
            context.sendResult "Method `#{method}` of `#{controllerName}.#{action}` is not allowed"

  getPort: => process.env.NODE_PORT or @config.port

  listen: (callback)=>

    @express.listen @getPort(), ->

    callback()


  start: (callback)=>

    async.waterfall(
      [
        @setupStatic
        @pong
        @listen
      ]
      callback
    )

  pong: (callback)=>

    if @config.pong
      @express.options "*", (req, res)->
        new Vakoo.WebContext(req, res, "Unnamed", "pong").sendResult()
      callback()
    else callback()

  setupStatic: (callback)=>

    if @config.static

      if @config.static.cache

        @setupCachedStatic callback

      else

        @setupExpressStatic callback

    else callback()

  setupExpressStatic: (callback)=>

    @addMiddleware "/", Express.static( Vakoo.Static.resolveFromCwd(@config.static.path) )

    callback()

  setupCachedStatic: (callback)=>

    createStatic {
      dir: Vakoo.Static.resolveFromCwd(@config.static.path)
    }, (err, middleware)=>

      if err
        @logger.error err
        @setupExpressStatic callback
      else
        @addMiddleware "/", middleware
        callback()


module.exports = WebServer