_ = require "underscore"

constants = {
  ENV_DEFAULT: "default"

  STORAGE_POSTGRE: "postgre"

  STORAGE_MIGRATIONS_COLLECTION: "_migrations"

  FOLDER_CONFIGS: "configs"
  FOLDER_CONTROLLERS: "controllers"
  FOLDER_INITIALIZERS: "initializers"
  FOLDER_TIMERS: "timers"
  FOLDER_QUEUES: "queues"
  FOLDER_SCRIPTS: "scripts"
  FOLDER_MIGRATIONS: "migrations"
  FOLDER_MIGRATIONS_MYSQL: "mysql"
  FOLDER_MIGRATIONS_MONGO: "mongo"
  FOLDER_MIGRATIONS_POSTGRE: "postgre"

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
      PATH_QUEUES: Vakoo.Static.resolveFromCwd constants.FOLDER_QUEUES
      PATH_SCRIPTS: Vakoo.Static.resolveFromCwd constants.FOLDER_SCRIPTS
      PATH_MIGRATIONS: Vakoo.Static.resolveFromCwd constants.FOLDER_MIGRATIONS
      PATH_MIGRATIONS_MYSQL: Vakoo.Static.resolveFromCwd constants.FOLDER_MIGRATIONS + constants.PATH_SEPARATOR + constants.FOLDER_MIGRATIONS_MYSQL
      PATH_MIGRATIONS_MONGO: Vakoo.Static.resolveFromCwd constants.FOLDER_MIGRATIONS + constants.PATH_SEPARATOR + constants.FOLDER_MIGRATIONS_MONGO
      PATH_MIGRATIONS_POSTGRE: Vakoo.Static.resolveFromCwd constants.FOLDER_MIGRATIONS + constants.PATH_SEPARATOR + constants.FOLDER_MIGRATIONS_POSTGRE
    }

module.exports = Constants