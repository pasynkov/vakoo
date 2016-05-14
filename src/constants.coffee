_ = require "underscore"

constants = {
  ENV_DEFAULT: "default"

  FOLDER_CONFIGS: "configs"
  FOLDER_CONTROLLERS: "controllers"

  FILE_PACKAGE_JSON: "package.json"

  PACKAGE_INFO:
    version: "0.0.1"
    description: ""
    keywords: ""
    author: ""
    license: "GNU"
}


class Constants

  constructor: (Vakoo)->

    _.extend @, constants

    _.extend @, {

      PATH_PACKAGE_JSON: Vakoo.Static.resolveFromCwd constants.FILE_PACKAGE_JSON

      PATH_CONFIGS: Vakoo.Static.resolveFromCwd constants.FOLDER_CONFIGS
      PATH_CONTROLLERS: Vakoo.Static.resolveFromCwd constants.FOLDER_CONTROLLERS
    }

module.exports = Constants