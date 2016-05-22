_ = require "underscore"
_.string = require "underscore.string"

class Initializer

  constructor: (@name)->

    @logger = new Vakoo.Logger {
      label: "#{_.string.classify @name}Initializer"
    }

  _invoke: (callback)=>

    @logger.info "Invoke"

    @invoke (err)=>
      if err
        @logger.error "Invoke failed with err: `#{err}`"
      else
        @logger.info "Invoke successfully completed"
      callback()

  invoke: (callback)-> callback()


module.exports = Initializer