Express = require "express"
BodyParser = require "body-parser"
CookieParser = require "cookie-parser"
Compression = require "compression"
createStatic = require "connect-static"

class WebServer

  constructor: (@config)->

    @express = Express()

    @express.use Compression()
    @express.use BodyParser.json()
    @express.use BodyParser.text()
    @express.use BodyParser.raw()
    @express.use BodyParser.urlencoded(
      extended: true
    )
    @express.use CookieParser()

  addRoute: (method, route, controllerName, action)->
    @express[method] route, (req, res)->
      context = new Vakoo.WebContext req, res, controllerName, action
      new app.controllers[controllerName](context)[action]()

  getPort: => process.env.NODE_PORT or @config.port

  listen: =>

    @express.listen @getPort(), ->


  start: (callback)=>

    @listen()

    callback()

#    if @config.static
#
#      if @config.cacheStatic
#        createStatic {dir: "#{Path.resolve('.')}/#{@config.static}"}, (err, middleware)=>
#          if err
#            @server.use '/', Express.static("#{Path.resolve('.')}/#{@config.static}")
#          else
#            @server.use "/", middleware
#          start()
#      else
#        @server.use '/', Express.static("#{Path.resolve('.')}/#{@config.static}")
#        start()
#
#    else
#      @server.use '/', Express.static("#{Path.resolve('.')}/static")
#      start()


module.exports = WebServer