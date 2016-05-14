_ = require "underscore"

constants = {
  ENV_DEFAULT: "default"

  FOLDER_CONFIGS: "configs"
  FOLDER_CONTROLLERS: "controllers"
  FOLDER_INITIALIZERS: "initializers"
  FOLDER_TIMERS: "timers"
  FOLDER_SCRIPTS: "scripts"
  FOLDER_MIGRATIONS: "migrations"
  FOLDER_MIGRATIONS_MYSQL: "mysql"
  FOLDER_MIGRATIONS_MONGO: "mongo"

  FILE_PACKAGE_JSON: "package.json"

  PACKAGE_INFO:
    version: "0.0.1"
    description: ""
    keywords: ""
    author: ""
    license: "GNU"

  PATH_SEPARATOR: "/"

  EXT_COFFEE: ".coffee"
}


class Constants

  constructor: (Vakoo)->

    _.extend @, constants

    _.extend @, {

      PATH_PACKAGE_JSON: Vakoo.Static.resolveFromCwd constants.FILE_PACKAGE_JSON

      PATH_CONFIGS: Vakoo.Static.resolveFromCwd constants.FOLDER_CONFIGS
      PATH_CONTROLLERS: Vakoo.Static.resolveFromCwd constants.FOLDER_CONTROLLERS
      PATH_INITIALIZERS: Vakoo.Static.resolveFromCwd constants.FOLDER_INITIALIZERS
      PATH_TIMERS: Vakoo.Static.resolveFromCwd constants.FOLDER_TIMERS
      PATH_SCRIPTS: Vakoo.Static.resolveFromCwd constants.FOLDER_SCRIPTS
      PATH_MIGRATIONS: Vakoo.Static.resolveFromCwd constants.FOLDER_MIGRATIONS
      PATH_MIGRATIONS_MYSQL: Vakoo.Static.resolveFromCwd constants.FOLDER_MIGRATIONS + constants.PATH_SEPARATOR + constants.FOLDER_MIGRATIONS_MYSQL
      PATH_MIGRATIONS_MONGO: Vakoo.Static.resolveFromCwd constants.FOLDER_MIGRATIONS + constants.PATH_SEPARATOR + constants.FOLDER_MIGRATIONS_MONGO
    }

module.exports = Constants