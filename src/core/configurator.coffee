
constants = require "./constants"
Path = require "path"

class Configurator

  constructor: (@environment)->

    @environment ?= constants.DEFAULT_ENVIRONMENT

    @projectConfig = require Path.resolve ".", constants.CONFIG_DIR, @environment, constants.PROJECT_CONFIG_FILE

    @package = require Path.resolve(".", "package.json")

    @instanceName = @package.name + "_" + @environment

    if @projectConfig.storage
      @storage = @projectConfig.storage

    if @projectConfig.initializers?.length
      @initializers = @projectConfig.initializers

    if @projectConfig.crons?.length
      @crons = @projectConfig.crons

    if @projectConfig.web
      @web = @projectConfig.web
      @web.Router = require Path.resolve ".", constants.CONFIG_DIR, @environment, constants.ROUTER_FILE



module.exports = Configurator