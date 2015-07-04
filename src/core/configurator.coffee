
constants = require "./constants"
Path = require "path"

class Configurator

  constructor: (@environment)->

    @projectConfig = require Path.resolve ".", constants.CONFIG_DIR, constants.DEFAULT_CONFIG_SCOPE, constants.PROJECT_CONFIG_FILE

    @package = require Path.resolve(".", "package.json")

    @instanceName = @package.name + "_" + @environment

    if @projectConfig.storage
      @storage = @projectConfig.storage

    if @projectConfig.web
      @web = @projectConfig.web
      @web.Router = require Path.resolve ".", constants.CONFIG_DIR, constants.DEFAULT_CONFIG_SCOPE, constants.ROUTER_FILE



module.exports = Configurator