
_ = require "underscore"
redis = require "redis"


class Redis


  constructor: (@name, @config)->

    @logger = vakoo.logger.redis

    @config = _.defaults @config, vakoo.constants.DEFAULT_REDIS_CONFIG

    @client =
      connected: false

  connect: (callback) =>

    @client = redis.createClient @config.port, @config.host, {retry_max_delay: 5000}

    if @config.database
      @client.select @config.database
    if @config.password
      @client.auth @config.password

    @client.on "connect", =>

      @logger.info "`#{@name}` connected successfully"

      if @config.startupClean
        @logger.info "`#{@name}` start clean"
        @client.keys "#{vakoo.configurator.instanceName}*", (err, keys)=>
          if err
            @logger.error "`#{@name}` clean failed with err: `#{err}`"
            callback()
          else

            unless keys.length
              @logger.info "`#{@name}` cleaner not found keys, completed"
              return callback()

            @client.del keys, (err)=>
              if err
                @logger.error "`#{@name}` clean failed with err: `#{err}`"
              else
                @logger.info "`#{@name}` cleaner successfully remove `#{keys.length}` keys, completed"
              callback()

      else
        callback()

    @client.on "error", (err)=>

      @logger.error "`#{@name}` error: `#{err}`"


  connected: =>

    return @client.connected


module.exports = Redis