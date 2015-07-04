
Redis = require "./redis"

_ = require "underscore"
async = require "async"


class Storage

  constructor: ->

    @config = vakoo.configurator.storage

    @logger = vakoo.logger.storage

    @connectors = []

    if @config.redis
      unless @config.redis.main
        @config.redis =
          main: _.clone @config.redis

    for type, config of @config
      if type in vakoo.constants.DEFINED_STORAGES
        for storageName, storageConfig of config
          @add type, storageName, storageConfig


  add: (type, name, config)=>

    unless type in ["redis"]
      return @logger.warn "Unkown storage type `#{type}`"

    @[type] ?= {}

    if type is "redis"
      @[type][name] = new Redis name, config

    if name is "main"
      vakoo[type] = @[type][name]

    @connectors.push @[type][name].connect


  connect: (callback)=>

    async.parallel @connectors, (err)=>
      if err
        @logger.error "Connect filed: `#{err}`"
      else
        @logger.info "Connected successfully"

      callback err

module.exports = Storage