program = require "commander"
winston = require "winston"

Creator = require "./manager/creator"
Migrator = require "./manager/migrator"

class VakooManager

  constructor: ->

    @logger = @getLogger "VakooManager"

  init: ->

    program.command "start"
    .action =>
      @logger.info "aza"

    program.command "watch"
    .action =>
      @logger.info "Start watch directory ..."

    program.command "create <type> <name> <storage>"
    .action (type, name, storage)=>

      @logger.info "Run `create` action with type `#{type}` and name `#{name}`. Storage is `#{storage}`"

      creator = new Creator type, name, storage
      creator.create()

    program.command "migrate <direction> <storage>"
    .action (direction, storage)=>

      @logger.info "Run migration `#{storage}`"

      migrator = new Migrator direction, storage

      migrator.run (err)=>
        process.exit if err then 1 else 0




    program.parse process.argv


  getLogger: (label)->
    return winston.loggers.add label, {
      console:
        colorize: true
        label: label
    }

global.manager = new VakooManager()

manager.init()




