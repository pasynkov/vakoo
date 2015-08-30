
Redis = require "./redis"
Mysql = require "./mysql"
Mongo = require "./mongo"

_ = require "underscore"
async = require "async"


class Storage

  constructor: ->

    @config = _.omit(vakoo.configurator.storage, "enable")

    @logger = vakoo.logger.storage

    @connectors = []

    for type, config of @config

      unless @config[type].main
        config =
          main: _.clone @config[type]

      if type in vakoo.constants.DEFINED_STORAGES
        for storageName, storageConfig of config
          @add type, storageName, storageConfig
      else
        @logger.warn "Unkown storage type `#{type}`"

  add: (type, name, config)=>

    @[type] ?= {}

    if type is "redis"
      @[type][name] = new Redis name, config

    if type is "mysql"
      @[type][name] = new Mysql name, config

    if type is "mongo"
      @[type][name] = new Mongo name, config

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