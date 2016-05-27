pg = require "pg"
builder = require "mongo-sql"
_ = require "underscore"
_.string = require "underscore.string"

class Postgre

  constructor: (@_config, @name = "main")->

    @logger = new Vakoo.Logger {
      label: "Postgre#{_.string.classify @name}"
    }

    @config =
      host: @_config.host or "localhost"
      username: @_config.username
      password: @_config.password
      database: @_config.database
      port: @_config.port or 5432

  isMain: => @_config.isMain is true

  #TODO autoreconnect
  connect: (callback)=>

    connString = "postgres://#{@config.username}:#{@config.password}@#{@config.host}:#{@config.port}/#{@config.database}"

    @client = new pg.Client connString

    @client.connect (err)=>

      if err
        @logger.error "Connection failed with err: `#{err}`"
        callback err, @
      else
        @logger.info "Connected successfully"
        callback null, @

  execute: (query, callback)=>

    @client.query query, callback



module.exports = Postgre