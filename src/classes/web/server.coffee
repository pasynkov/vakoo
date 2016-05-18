Express = require "express"
BodyParser = require "body-parser"
CookieParser = require "cookie-parser"
Compression = require "compression"
createStatic = require "connect-static"

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

    @_currentRoutes = []

  hasRoutes: => not _.isEmpty @_currentRoutes

  addMiddleware: ([path]..., middleware)=>

    if path
      @express.use path, middleware
    else
      @express.use middleware

  addRoute: (method, route, controllerName, action = null)->

    if method is "*"
      method = "all"

    @_currentRoutes.push [method, route, controllerName, action]

    @express[method] route, (req, res)->
      context = new Vakoo.WebContext req, res, controllerName, action
      new app.web.controllers[controllerName](context)[context.getAction()]()

  getPort: => process.env.NODE_PORT or @config.port

  listen: (callback)=>

    @express.listen @getPort(), ->

    callback()


  start: (callback)=>

    async.waterfall(
      [
        @setupStatic
        @listen
      ]
      callback
    )

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