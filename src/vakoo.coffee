
Configurator = require "./core/configurator"
Initializer = require "./core/initializer"
Logger = require "./core/logger"
constants = require "./core/constants"

class Vakoo

  constructor: ->

    @environment = process.env.NODE_ENV or constants.DEFAULT_ENVIRONMENT

    @configurator = new Configurator @environment

    @logger = new Logger @configurator

    @constants = constants

    @logger.main.info "Vakoo's Logger and Configurator initialized successfully"

  initialize: (callback)->

    @initializer = new Initializer

    @initializer.run callback


module.exports = Vakoo

