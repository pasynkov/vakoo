
constants = require "./constants"
Path = require "path"
_ = require "underscore"

class Configurator

  constructor: (@context, @environment = constants.DEFAULT_ENVIRONMENT)->

    @envConfig = require Path.resolve ".", constants.CONFIG_DIR, @environment, @context or "config"

    @defaultConfig = require Path.resolve ".", constants.CONFIG_DIR, constants.DEFAULT_ENVIRONMENT, @context or "config"

    @envConfig = _.defaults @envConfig, @defaultConfig

    @package = require Path.resolve(".", "package.json")

    if @context
      @contextConfig = require Path.resolve ".", constants.CONFIG_DIR, @environment, @context
      @instanceName = vakoo.instanceName = @package.name + "_" + @context + "_" + @environment

      @config = {}

      for key, val of @envConfig
        @config[key] = _.defaults @contextConfig[key] ? {}, val

      @config = _.defaults @contextConfig, @config

    else
      @config = @envConfig
      @instanceName = vakoo.instanceName = @package.name + "_" + @environment

    if @config.storage

      @config.storage = _.defaults @config.storage, @defaultConfig.storage

      if not _.isEmpty(@config.storage) and @config.storage.enable isnt false
        @config.storage.enable = true
      @storage = @config.storage

    if @config.initializers?.length
      @initializers = @config.initializers

    if @config.crons?.length
      @crons = @config.crons

    unless _.isEmpty @config.subscribe
      @subscribe = @config.subscribe

    if @config.web
      @web = @config.web
      try
        @web.Router = require Path.resolve ".", constants.CONFIG_DIR, @environment, constants.ROUTER_FILE
      catch
        @web.Router = require Path.resolve ".", constants.CONFIG_DIR, constants.DEFAULT_ENVIRONMENT, constants.ROUTER_FILE



module.exports = Configurator