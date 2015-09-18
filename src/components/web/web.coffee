
WebServer = require "./web_server"

class Web

  constructor: ->

    @server = new WebServer

    @config = vakoo.configurator.web

    @router = new @config.Router @server

    @logger = vakoo.logger.web


  start: (callback)=>

    @logger.info "run port listening"

    @server.start =>
      @logger.info "start listen port `#{@config.port}`"
      callback()


module.exports = Web