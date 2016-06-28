_ = require "underscore"
_.string = require "underscore.string"
redis = require "redis"


class Redis


  constructor: (config, @name = "main")->

    @_config = config

    @config = {
      host: @_config.host or "localhost"
      port: @_config.port or 6379
      database: @_config.database or false
      password: @_config.password or false
    }

    @logger = new Vakoo.Logger {
      label: "Redis#{_.string.classify @name}"
    }

    @subscribers = {}

    @client =
      connected: false

  getPathToRewritable: -> _.last __filename.split "src/"

  isMain: => @_config.isMain is true

  connect: (callback) =>

    @client = redis.createClient @config.port, @config.host

    if @config.database
      @client.select @config.database
    if @config.password
      @client.auth @config.password

    @client.on "connect", =>

      @logger.info "Connected successfully"

      if @config.startupClean
        @logger.info "`#{@name}` start clean"
        @client.keys "#{_app.name}*", (err, keys)=>
          if err
            @logger.error "Clean failed with err: `#{err}`"
            callback null, @
          else

            unless keys.length
              @logger.info "Cleaner not found keys, completed"
              return callback null, @

            @client.del keys, (err)=>
              if err
                @logger.error "Clean failed with err: `#{err}`"
              else
                @logger.info "Cleaner successfully remove `#{keys.length}` keys, completed"
              callback null, @

      else
        callback null, @

    @client.on "error", (err)=>

      @logger.error "`#{@name}` error: `#{err}`"


  connected: =>

    return @client.connected


  getex: (key, getter, ttl, callback)=>
    if @connected()
      @client.get key, (error, result)=>
        if error
          getter callback
        else
          if result?
            try
              result = JSON.parse result
              result = if result.redisResult? then result.redisResult else result
            callback null, result
          else
            getter (err, result)=>
              if err or not result?
                callback err
              else
                if _.isArray(result) or _.isObject(result)
                  redisValue = JSON.stringify redisResult:result
                @client.setex key, ttl, redisValue ? result, (err)->
                  callback err, result
    else
      getter callback

  get: (key, getter, callback)=>
    if @connected()
      @client.get key, (error, result)=>
        if error
          getter callback
        else
          if result?
            try
              result = JSON.parse result
              result = if result.redisResult? then result.redisResult else result
            callback null, result
          else
            getter (err, result)=>
              if err or not result?
                callback err
              else
                if _.isArray(result) or _.isObject(result)
                  redisValue = JSON.stringify redisResult:result
                @client.set key, redisValue ? result, (err)->
                  callback err, result
    else
      getter callback

  subscribe: (name, config, callback)=>

    @subscribers[name] = {
      config
      redis: new Redis "#{name}Subscriber", @config
      logger: vakoo.logger.addLogger "#{name}Subscriber"
    }

    @subscribers[name].redis.connect =>

      client = @subscribers[name].redis.client

      @subscribers[name].logger.info "Successfully connected"

      Script = require "#{process.cwd()}/subscribers/#{config.script}"

      for channel in config.channels
        client.subscribe channel
        @subscribers[name].logger.info "Successfully subscribed to channel `#{channel}`"

      client.on "message", (channel, message)=>

        @subscribers[name].logger.info "Incoming message from channel `#{channel}`"

        try
          message = JSON.parse message

        new Script channel, message, (err)=>
          if err
            @subscribers[name].logger.error "Event failed with err: `#{err}`"
          else
            @subscribers[name].logger.info "Event complete successfully"

      callback()





module.exports = Redis