
constants = require "./constants"
Path = require "path"
_ = require "underscore"

class Configurator

  constructor: (@context, @environment = constants.DEFAULT_ENVIRONMENT)->

    @envConfig = require Path.resolve ".", constants.CONFIG_DIR, @environment, "config"

    @package = require Path.resolve(".", "package.json")

    if @context
      @contextConfig = require Path.resolve ".", constants.CONFIG_DIR, @context, "config"
      @instanceName = vakoo.instanceName = @package.name + "_" + @context + "_" + @environment

      @config = {}

      for key, val of @envConfig
        @config[key] = _.defaults @contextConfig[key] ? {}, val

      @config = _.defaults @contextConfig, @config

    else
      @config = @envConfig
      @instanceName = vakoo.instanceName = @package.name + "_" + @environment

    if @config.storage
      @storage = @envConfig.storage

    if @config.initializers?.length
      @initializers = @config.initializers

    if @config.crons?.length
      @crons = @config.crons

    if @config.web
      @web = @config.web
      @web.Router = require Path.resolve ".", constants.CONFIG_DIR, @environment, constants.ROUTER_FILE



module.exports = Configurator