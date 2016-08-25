_ = require "underscore"
_.string = require "underscore.string"

class Batch

  constructor: (@name, @config)->

    @logger = new Vakoo.Logger {
      label: "#{_.string.classify @name}Batch"
    }

  getPathToRewritable: -> _.last __filename.split "src/"

module.exports = Batch