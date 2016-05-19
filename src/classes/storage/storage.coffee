async = require "async"
_ = require "underscore"

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

    @createConnections(
      @parseConfig(@config.mongo)
      Vakoo.Mongo
      (err, connections)=>
        return callback err if err

        return callback err unless connections

        extender = {}

        for conn in connections
          extender[conn.name] = conn
          if conn.isMain()
            extender[conn.name] = conn
            @mongo = conn
            _app.mongo = conn

        _.extend @mongo, extender
        _.extend _app.mongo, extender

        callback()
    )

  parseConfig: (rawConfig)->

    return false unless rawConfig

    config = {}

    if rawConfig.host
      config.main = rawConfig
      config.main.isMain = true
      config
    else
      mainName = _.first _.keys rawConfig
      rawConfig[mainName].isMain = true
      rawConfig


  createConnections: (config, Database, callback)=>

    return callback() unless config

    async.map(
      _.keys config
      (configKey, done)=>

        connConfig = config[configKey]

        connection = new Database connConfig, configKey

        connection.connect done

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
            _app.mysql ?= {}
            _app.mysql = @main


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