async = require "async"
_ = require "underscore"

class Application

  constructor: (@env)->

    @logger = new Vakoo.Logger {
      label: "Application"
    }

    @configs = new Vakoo.Configurator @env

  initialize: (callback)=>

    @logger.info "Initialize"

    async.auto(
      {
        config: @configs.initialize
        web: [
          "config"
          @initializeWeb
        ]
      }
      callback
    )

  initializeWeb: (..., callback)=>

    if not _.isEmpty(@configs.web) and @configs.web.enable isnt false
      @web = new Vakoo.Web @configs.web

      @web.initialize callback

    else callback()

  start: ->
    console.log "app start"


module.exports = Application