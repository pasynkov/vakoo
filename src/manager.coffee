program = require "commander"
winston = require "winston"

Creator = require "./manager/creator"

class VakooManager

  constructor: ->

    @logger = @getLogger "VakooManager"

  init: ->

    program.command "watch"
    .action =>
      @logger.info "Start watch directory ..."

    program.command "create <type> <name>"
    .action (type, name)=>

      @logger.info "Run `create` action with type `#{type}` and name `#{name}`"

      creator = new Creator type, name
      creator.create()




    program.parse process.argv


  getLogger: (label)->
    return winston.loggers.add label, {
      console:
        colorize: true
        label: label
    }

global.manager = new VakooManager()

manager.init()




