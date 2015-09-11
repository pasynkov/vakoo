
Configurator = require "./core/configurator"
Initializer = require "./core/initializer"
Logger = require "./core/logger"
constants = require "./core/constants"
commands = require "./core/commands"

program = require "commander"
async = require "async"

class Vakoo

  constructor: (callback)->

    global.vakoo = @

    @constants = constants

    @logger = new Logger

    for action, params of commands
      do (action, params)=>

        emitter = program.command action

        if params.options
          for option in params.options
            emitter.option "-#{option[0]} --#{option[1]} #{option[2][0]}#{option[1]}#{option[2][1]}"
        emitter.action (args)=>
          if @["action#{params.name}"]?
            @["action#{params.name}"].apply @, [args, callback]
          else
            @logger.main.error "Action `#{params.name}` not found"

    program.parse process.argv

  actionWatch: ()=>

  actionStart: ()=>

  actionRun: ({script, env, context}, callback)=>

    unless script
      return callback "Param `script` is not defined"

    @configurator = new Configurator context, env

    @logger = new Logger

    @initializer = new Initializer =>

      [dir, file] = script.split("/")

      unless file
        [file, dir] = [dir, file]

      dir ?= "scripts"

      @logger.main.info "Run script `#{script}`"

      try
        Script = require process.cwd() + "/" + [dir, file].join("/")
        new Script (err)=>
          if err
            @logger.main.error "Script `#{script}` crashed with err: `#{err}`"
          else
            @logger.main.info "Script `#{script}` completed successfully"

          process.exit(if err then 1 else 0)

      catch e
        callback e





module.exports = Vakoo

