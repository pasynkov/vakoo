
_ = require "underscore"
MongoDB = require 'mongodb'

class Mongo

  constructor: (@name, @config)->

    @logger = vakoo.logger.mongo

    @config = _.defaults @config, vakoo.constants.DEFAULT_MONGO_CONFIG

    @client =
      connected: false

  connect: (callback)=>

    connectString = 'mongodb://'
    if @config.username
      connectString += "#{@config.username}:#{@config.password}@"
    connectString += "#{@config.host}:#{@config.port}/#{@config.name}"

    client = new MongoDB.MongoClient()

    opts =
      db:
        retryMiliSeconds: 500
        numberOfRetries: 1000000
      server:
        auto_reconnect: true
        socketOptions:
          connectTimeoutMS: 100000
          socketTimeoutMS: 100000

    client.connect connectString, opts, (error, connection)=>
      if error
        @logger.error error
        callback error
      else
        @logger.info "`#{@name}` connected successfully"
        @client = connection
        callback()

  collection: (name)=>
    @client.collection(name)


module.exports = Mongo