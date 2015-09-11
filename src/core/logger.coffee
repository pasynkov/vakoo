
constants = require "./constants"
winston = require "winston"
_ = require "underscore"

class Logger

  constructor: ->

    @config = @extendConfig vakoo.configurator?.config?.loggers or @getDefaultConfig()

    @initialize()


  getDefaultConfig: ->
    _.object(
      _.map(
        constants.DEFAULT_LOGGERS
        (loggerName)-> [loggerName, {}]
      )
    )


  extendConfig: (config)->
    config = _.defaults config, @getDefaultConfig()

    for loggerName, loggerConfig of config
      loggerConfig = _.defaults loggerConfig, constants.DEFAULT_LOGGER_CONFIG

    config

  initialize: ->

    for loggerName, loggerConfig of @config

      label = (loggerConfig.label or loggerName[0].toUpperCase() + loggerName[1...]) + ""

      delete loggerConfig.label

      for transportName, transportConfig of loggerConfig
        transportConfig.label = label

      @[loggerName] = winston.loggers.add loggerName, loggerConfig


module.exports = Logger