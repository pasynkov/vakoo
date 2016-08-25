_ = require "underscore"
elasticsearch = require "elasticsearch"

class Elastic

  @module = elasticsearch

  constructor: (@_config, @name = "main")->

    @logger = new Vakoo.Logger {
      label: "Elastic#{_.string.classify @name}"
    }

  getPathToRewritable: -> _.last __filename.split "src/"

  isMain: => @_config.isMain is true

  connect: (callback)=>

    @logger.warn "Connector is empty!"

    callback null, @


module.exports = Elastic