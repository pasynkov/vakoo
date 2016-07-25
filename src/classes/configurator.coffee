_ = require "underscore"

class Configurator

  constructor: (@env, @context)->

    @logger = new Vakoo.Logger {
      label: "Configurator"
    }

  initialize: (callback)=>
    @logger.info "Initialize with env `#{@env}`"

    Config = require Vakoo.c.PATH_CONFIGS + Vakoo.c.PATH_SEPARATOR + @env

    config = new Config @env, @context

    _.extend @, config

    if @context
      @logger.info "Implement context `#{@context}`"

      try
        Context = require(Vakoo.c.PATH_CONFIGS + Vakoo.c.PATH_SEPARATOR + @context)
        context = new Context @
        _.extend @, context
      catch e
        @logger.error "Failed initialize context with err: `#{e.toString()}`"

    callback()




module.exports = Configurator