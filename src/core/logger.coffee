
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

  initialize: =>

    for loggerName, loggerConfig of @config

      @addLogger loggerName, loggerConfig


  addLogger: (name, config = {})->

    config = _.defaults config, constants.DEFAULT_LOGGER_CONFIG

    label = (config.label or name[0].toUpperCase() + name[1...]) + ""

    delete config.label

    for transportName, transportConfig of config
      transportConfig.label = label

    @[name] = winston.loggers.add name, config

    return @[name]


module.exports = Logger