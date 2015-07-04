program = require "commander"

Creator = require "./manager/creator.coffee"

class VakooManager

  constructor: ->

    program
      .command "watch"
      .action ->
        console.log "hello"

      .command "create <type> <name>"
      .action (type, name)->
        creator = new Creator type, name
        creator.create()




    program.parse process.argv



new VakooManager()




