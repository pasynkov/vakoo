async = require "async"
_ = require "underscore"

MYSQL = "mysql"
MONGO = "mongo"

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
          @initializeRedis
        ]
      ]
      callback
    )

  initializeMongo: (callback)=>

    @createConnections(
      @parseConfig(@config.mongo)
      Vakoo.Mongo
      @extendConnections callback
    )

  initializeMysql: (callback)=>
    @createConnections(
      @parseConfig(@config.mysql)
      Vakoo.Mysql
      @extendConnections callback
    )

  initializeRedis: (callback)=>

    @createConnections(
      @parseConfig(@config.redis)
      Vakoo.Redis
      @extendConnections callback
    )


  extendConnections: (callback)=>

    (err, connections)=>
      return callback err if err
      return callback err unless connections

      additionalConns = []

      for conn in connections
        if conn.isMain()
          if conn instanceof Vakoo.Mysql
            @mysql = conn
          else if conn instanceof Vakoo.Mongo
            @mongo = conn
          else if conn instanceof Vakoo.Redis
            @redis = conn
        else
          additionalConns.push conn

      for conn in additionalConns

        if conn instanceof Vakoo.Mysql
          @mysql[conn.name] = conn
        else if conn instanceof Vakoo.Mongo
          @mongo[conn.name] = conn
        else if conn instanceof Vakoo.Redis
          @redis[conn.name] = conn

      _app.mysql = @mysql
      _app.mongo = @mongo
      _app.redis = @redis


      callback()


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



module.exports = Storage