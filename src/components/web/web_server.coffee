
express = require "express"
Context = require "./context"

Path = require "path"

class WebServer

  constructor: ->

    @server = express()

    @config = vakoo.configurator.web


  addRoute: (method, route, controllerName, action)->
    @server[method] route, (req, res)->
      Controller = require Path.resolve ".", vakoo.constants.CONTROLLERS_DIR, controllerName
      context = new Context req, res, controllerName, action
      controller = new Controller context
      controller[action]()


  start: (callback)=>
    @server.listen @config.port, =>
      callback()



module.exports = WebServer