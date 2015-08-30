
Express = require "express"
BodyParser = require 'body-parser'
CookieParser = require 'cookie-parser'
Compression = require 'compression'
createStatic = require 'connect-static'
Context = require "./context"

Path = require "path"

class WebServer

  constructor: ->

    @server = Express()

    @server.use Compression()
    @server.use BodyParser.json()
    @server.use BodyParser.text()
    @server.use BodyParser.raw()
    @server.use BodyParser.urlencoded(
      extended: true
    )
    @server.use CookieParser()

    @config = vakoo.configurator.web


  addRoute: (method, route, controllerName, action)->
    @server[method] route, (req, res)->
      Controller = require Path.resolve ".", vakoo.constants.CONTROLLERS_DIR, controllerName
      context = new Context req, res, controllerName, action
      controller = new Controller context
      controller[action]()


  start: (callback)=>

    start = =>
      @server.listen @config.port, =>
      callback()

    if @config.static

      if @config.cacheStatic
        createStatic {dir: "#{Path.resolve('.')}/#{@config.static}"}, (err, middleware)=>
          if err
            @server.use '/', Express.static("#{Path.resolve('.')}/#{@config.static}")
          else
            @server.use "/", middleware
          start()
      else
        @server.use '/', Express.static("#{Path.resolve('.')}/#{@config.static}")
        start()

    else
      @server.use '/', Express.static("#{Path.resolve('.')}/static")
      start()





module.exports = WebServer