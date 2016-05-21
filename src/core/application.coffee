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

    async.auto(
      {
        config: @configs.initialize
        storage: [
          "config"
          @initializeStorage
        ]
        web: [
          "config"
          "storage"
          @initializeWeb
        ]
        end: [
          "web"
          Vakoo.Utils.asyncLog @logger.info, "Initialized successfully"
        ]
      }
      callback
    )

  initializeWeb: (..., callback)=>

    if not _.isEmpty(@configs.web) and @configs.web.enable isnt false
      @web = new Vakoo.Web @configs.web

      @web.initialize callback

    else callback()

  initializeStorage: (..., callback)=>

    if not _.isEmpty(@configs.storage) and @configs.storage.enable isnt false
      @storage = new Vakoo.Storage @configs.storage

      @storage.initialize callback

    else callback()



module.exports = Application