_ = require "underscore"
_.string = require "underscore.string"

class Config

  constructor: (@name, @context)->

    @logger = new Vakoo.Logger {
      label: "#{_.string.classify @name}Config#{if @context then "::" + _.string.classify(@context) else ""}"
    }

    @logger.info "Implemented"

  getPathToRewritable: -> _.last __filename.split "src/"

  isEnv: -> true

module.exports = Config