_ = require "underscore"
_.string = require "underscore.string"
MongoDB = require "mongodb"
async = require "async"

class MongoCollection

  constructor: (@collection)->

  find: ([query, fields, options] ..., callback)=>

    query ?= {}

    @collection.find query, fields, options, (err, cursor)->
      if err
        return callback err
      cursor.toArray callback


  count: ([query, options]..., callback)=>

    @collection.count query, options, callback


  findOne: ([query, fields, options] ..., callback)=>

    if query._id
      try
        query._id = MongoDB.ObjectID query._id

    @collection.findOne query, fields, options, callback


class Mongo

  constructor: (config, @name = "main")->

    @_config = config

    @logger = new Vakoo.Logger {
      label: "Mongo#{_.string.classify @name}"
    }

    @config = {
      username: config.username
      password: config.password
      host: config.host
      port: config.port or 27017
      database: config.database
    }

    @client =
      connected: false

  isMain: => @_config.isMain is true

  connect: (callback)=>

    connectString = 'mongodb://'
    if @config.username
      connectString += "#{@config.username}:#{@config.password}@"
    connectString += "#{@config.host}:#{@config.port}/#{@config.database}"

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
        @logger.info "Connected successfully"
        @client = connection
        callback null, @

  collection: (name)=>
    new MongoCollection @collectionNative name

  collectionNative: (name)=>
    @client.collection(name)


module.exports = Mongo