async = require "async"
_ = require "underscore"

MONGO = "mongo"
MYSQL = "mysql"

class DatabaseConfig

  constructor: (config)->

    @_isMain = config.isMain
    @_name = config.name
    @_config = _.omit config, ["name", "isMain"]

  isMain: -> @_isMain is true

  getName: -> @_name or "main"

  getConnectionConfig: -> @_config

  createConfigs: (rawConfig, type)->
    return false unless rawConfig

    ClassName = if type is MONGO then MongoConfig else MysqlConfig

    configs = []

    for config in DatabaseConfig::parseConfig(rawConfig)
      configs.push new ClassName config

    configs

  parseConfig: (rawConfig)-> [_.defaults(rawConfig, {name: "main", isMain: true})]

class MysqlConfig extends DatabaseConfig

  constructor: -> super

class MongoConfig extends DatabaseConfig

  constructor: -> super

  getDatabaseClass: -> Vakoo.Mongo

  getType: -> MONGO

class Storage

  constructor: (@config)->

    @logger = new Vakoo.Logger {
      label: "Storage"
    }

  initialize: (callback)=>

    async.waterfall(
      [
        async.apply async.parallel, [
          @initializeMysql
          @initializeMongo
        ]
      ]
      callback
    )

  initializeMongo: (callback)=>

    @createConnection DatabaseConfig::createConfigs(@config.mongo, MONGO), callback

  createConnection: (configs, callback)=>

    return callback() unless configs

    async.each(
      configs
      (config, done)=>

        app[config.getType()] ?= {}
        @[config.getType()] ?= {}

        driver = new config.getDatabaseClass()(config.getConnectionConfig(), config.getName())

        app[config.getType()][config.getName()] = @[config.getType()][config.getName()] = new config.getDatabaseClass()(config.getConnectionConfig(), config.getName())

        if config.isMain()
          app[config.getType()].main = @[config.getType()].main = @[config.getType()][config.getName()]

        console.log driver

        driver.connect done

      callback
    )


  initializeMysql: (callback)=>
    if (mysqlConfig = @validateConfig(@config.mysql, "mysql"))

      mainConnectionName = _.first _.keys mysqlConfig

      async.eachOf(
        mysqlConfig
        (config, connectionName, done)=>

          @[connectionName] = new Vakoo.Mysql config, connectionName

          if connectionName is mainConnectionName
            @main = @[connectionName]
            app.mysql ?= {}
            app.mysql = @main


          @[connectionName].connect done

        callback
      )

    else callback()

  validateConfig: (config, type)=>

    #todo validate logic
    if type is "mysql"

      if _.intersection(_.keys(config), ["host", "username", "password"]).length

        {main: config}

      else if _.isObject(config)

        if (mainConfig = @validateConfig(_.pick config, _.first(_.keys(config))))

          console.log "ADD MULTI CONFIG"

          return "aza"

        else false

      else false

    else false

module.exports = Storage