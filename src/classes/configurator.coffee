_ = require "underscore"

class Configurator

  constructor: (@env)->

    @logger = new Vakoo.Logger {
      label: "Configurator"
    }

    _.extend @, require(Vakoo.c.PATH_CONFIGS + Vakoo.c.PATH_SEPARATOR + @env)


  initialize: (callback)=>
    @logger.info "Initialize with env `#{@env}`"
    callback()




module.exports = Configurator