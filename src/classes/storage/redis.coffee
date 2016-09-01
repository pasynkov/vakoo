_ = require "underscore"
_.string = require "underscore.string"
async = require "async"
redis = require "redis"

class RedisList

  constructor: (@name, @redis)->

    @client = @redis.client

  append: (value, callback)=>

    @client.rpush @name, @redis.wrap(value), callback

  prepend: (value, callback)=>

    @client.lpush @name, @redis.wrap(value), callback

  remove: ([value, count]..., callback)=>

    count ?= 1

    @client.lrem @name, count, @redis.wrap(value), callback

  each: (handler, callback)=>

    @client.lrange @name, 0, -1, (err, items)=>
      return callback err if err

      async.each(
        items
        (item, done)=>
          handler @redis.unWrap(item), done
        callback
      )

  length: (callback)=>

    @client.llen @name, callback

  eachPop: (handler, callback)=>

    async.during(
      @length()
      (done)=>
        @client.lpop (err, item)=>
          return done err if err
          handler @redis.unWrap(item), done
      callback
    )

  get: (callback)=>

    @client.lrange @name, 0, -1, (err, items)=>
      return callback err if err

      callback null, _.map(
        items
        @redis.unWrap
      )

  remove: ([value, count]..., callback)=>

    count ?= 1

    @client.lrem @name, count, @redis.wrap(value), callback

  removeAll: (value, callback)=>

    @remove value, 0, callback

  removeOne: (value, callback)=>

    @remove value, 1, callback

class RedisCache

  constructor: (@name, @ttl, @redis)->

    @extractor = async.asyncify(-> null)

    @logger = @redis.logger

  extract: (@extractor = async.asyncify(->))=> @

  get: (callback)=>

    async.waterfall [
      (taskCallback)=> @redis.client.get @name, taskCallback
      async.asyncify @redis.unWrap
      (value, taskCallback)=>
        if value
          taskCallback null, value
        else
          @invokeExtractor taskCallback
    ], (err, value)=>
      if err
        @logger.error err
        return @extractor callback
      else callback null, value

  invokeExtractor: (callback)=>

    async.waterfall [
      @extractor
      @set
      @get
    ], callback

  set: (value, callback)=>

    method = "set"
    args = [@name]

    if @ttl
      method = "setex"
      args.push @ttl

    args.push @redis.wrap(value)
    args.push (err)-> callback err

    @redis.client[method].apply @redis.client, args


  refresh: (callback)=>

    async.series [
      @remove
      @get
    ], (err)-> callback err

  remove: (callback)=>

    @redis.client.del @name, (err)->
      callback err


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

  @List: RedisList

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

  list: (name)-> new Redis.List name, @

  cache: (name, ttl = false)=>
    new RedisCache name, ttl, @

  wrap: (value)->

    JSON.stringify {
      redisWrapper: value
    }

  unWrap: (value)->
    unless value
      return null

    result = null

    try
      result = JSON.parse(value).redisWrapper

    result


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

  subscribe: (channel, Handler)=>

    subscriber = new Redis @_config, "#{@name}Subscriber::#{channel}"

    subscriber.connect (err)=>
      if err
        return subscriber.logger.error "Subscribe fail with err: `#{err}`"

      @subscribers[channel] = subscriber

      client = subscriber.client

      client.on "subscribe", (channel)=>

        subscriber.logger.info "Subscribed to channel `#{channel}`"

      client.subscribe channel

      client.on "message", (channel, message)=>

        message = @unWrap message

        subscriber.logger.info "Incoming message on `#{channel}`"
        subscriber.logger.info message

        if _.isEmpty(Handler::)
          invoke = Handler
        else
          invoke = new Handler(channel).invoke

        invoke message, (err)=>
          if err
            subscriber.logger.error "Handler for channel `#{channel}` failed with err: `#{err}`"
          else
            subscriber.logger.info "Handler for channel `#{channel}` successfully completed"

  publish: (channel, message)=>

    @client.publish channel, @wrap(message)





module.exports = Redis