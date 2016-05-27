program = require "commander"
async = require "async"
_ = require "underscore"
_.string = require "underscore.string"

class Invoker

  constructor: ->

    @logger = new Vakoo.Logger {
      label: "Invoker"
    }

    @initializePrograms()

  initializePrograms: =>

    program
      .usage("<command> [options]")
      .version(Vakoo.package.version)

    program
      .command "init [name]"
      .alias "i"
      .description "create and initialize Vakoo application"
      .option "-e, --env [items]", "List of environment names. Ex: dev,test,stable", ((val, def)-> if val then val.split(",") else def), [Vakoo.c.ENV_DEFAULT]
      .action @init

    program
      .command "create"
      .alias "c"
      .usage("<type> [options] <names...>")
      .description "create application module (controller, timer and etc.)"
      .arguments "<type> <names...>"
      .option "-p, --path [path]", "Path of file (for scripts only)"
      .option "--mysql", "MySQL-type migration (for migrations only)"
      .option "--mongo", "Mongo-type migration (for migrations only)"
      .option "--postgre", "Postgre-type migration (for migrations only)"
      .option "-e, --env [items]", "List of environment names (Add module to that envs only)", ((val)-> val.split(",")), []
      .action @create
      .on "--help", Vakoo.Creator::getHelpText

    program
      .command "start"
      .alias "s"
      .description "start vakoo application with env (def. default)"
      .option "-e, --env [env]", "environment"
      .action @start

    program
      .command "run"
      .alias "r"
      .usage("<path>")
      .description "run application script"
      .arguments "<path>"
      .option "-e, --env [env]", "environment"
      .action @run

    program
      .command "migrate"
      .alias "m"
      .usage("<type> <databases...> [options]")
      .description "run migrate with setted databases (mysql, mongo, postgre)"
      .arguments "<type> <databases...>"
      .option "-e, --env [items]", "List of environment names", ((val)-> val.split(",")), []
      .action @migrate

    program.parse process.argv

  migrate: (type, databases, {env})=>

    async.waterfall(
      [
        async.apply @getProcessingEnv, env
        (env, taskCallback)=>
          taskCallback null, new Vakoo.Application(env)

        @globalizeApp

        (taskCallback)->
          _app.initializeConfigsAndStorage taskCallback

        (taskCallback)->

          migrator = new Vakoo.Migrator type, databases

          migrator.invoke taskCallback

      ]
      (err)=>
        if err
          @logger.error err
        process.exit()
    )

  globalizeApp: (_app, callback)=>

    window = {}
    window._app = _app
    global._app = _app

    callback()

  getProcessingEnv: (env, callback)=>

    async.waterfall(
      [
        if _.isEmpty(env) then @getAllEnvs else async.apply @getEnvByNames, env
        (envs, taskCallback)->
          if _.isEmpty(envs)
            taskCallback "Not found environment: `#{env}`"
          else
            taskCallback null, _.first(envs)
      ]
      callback
    )

  run: (path, {env})=>

    async.waterfall(
      [
        if _.isEmpty(env) then @getAllEnvs else async.apply @getEnvByNames, env
        (envs, taskCallback)->

          if _.isEmpty(envs)
            taskCallback "Not found environment: `#{env}`"
          else
            taskCallback null, _.first(envs)
        (env, taskCallback)->

          taskCallback null, new Vakoo.Application(env)

        (_app, taskCallback)->

          window = {}
          window._app = _app
          global._app = _app

          _app.initializeConfigsAndStorage taskCallback

        (taskCallback)=>

          scriptPath = Vakoo.Static.resolveFromCwd Vakoo.c.PATH_SCRIPTS + Vakoo.c.PATH_SEPARATOR + path

          if path.split(Vakoo.c.PATH_SEPARATOR).length > 1
            scriptPath = Vakoo.Static.resolveFromCwd path

          try
            Script = require scriptPath
          catch e
            return taskCallback e.toString()

          new Script().invoke taskCallback

      ]
      (err)=>
        if err
          @logger.error err
        process.exit()
    )

  start: ({env})=>

    async.waterfall(
      [
        if _.isEmpty(env) then @getAllEnvs else async.apply @getEnvByNames, env
        (envs, taskCallback)->

          if _.isEmpty(envs)
            taskCallback "Not found environment: `#{env}`"
          else
            taskCallback null, _.first(envs)
        (env, taskCallback)->

          taskCallback null, new Vakoo.Application(env)

        (_app, taskCallback)->

          window = {}
          window._app = _app
          global._app = _app

          _app.initialize taskCallback
      ]
      (err)=>
        if err
          @logger.error err
          process.exit()
    )

  create: (type, names, {env, mysql, mongo, postgre, path})=>

    async.waterfall(
      [
        if _.isEmpty(env) then @getAllEnvs else async.apply @getEnvByNames, env
        (envs, taskCallback)=>
          if _.isEmpty(envs)
            taskCallback "Not found environment(s): `#{env}`"
          else

            creator = new Vakoo.Creator {envs, mysql, mongo, postgre, path}

            async.each(
              names
              async.apply creator.createByType, type
              taskCallback
            )

      ]
      (err)=>
        @logger.error err if err
        process.exit()
    )

  getAllEnvs: (callback)=>

    async.waterfall(
      [
        async.apply Vakoo.Static.getDirFiles, Vakoo.c.PATH_CONFIGS
        async.asyncify (files)-> _.map files, Vakoo.Static.getFileNameWithoutExt
      ]
      callback
    )

  getEnvByNames: (envs, callback)=>

    async.waterfall(
      [
        @getAllEnvs
        async.apply async.asyncify(_.intersection), envs
      ]
      callback
    )


  init: (name = Vakoo.Static.getCwdFolderName(), {env})=>

    name = Vakoo.Utils.fileSlugify name

    async.waterfall(
      [
        Vakoo.Utils.asyncLog @logger.info, "Create application `#{name}` with env `#{env}`"
        async.apply Vakoo.Utils.generatePackageInfo, name

        @installVakoo

        Vakoo.Utils.asyncLog @logger.info, "Create folder(s)"

        async.apply async.each, [Vakoo.c.PATH_CONFIGS, Vakoo.c.PATH_CONTROLLERS], Vakoo.Static.createFolderIfNotExists

        Vakoo.Utils.asyncLog @logger.info, "Create configs for each env"

        async.apply async.each, env, (env, done)-> new Vakoo.Creator({env}).createConfigFile done

      ]
      (err)=>
        @logger.error err if err
        process.exit()
    )

  installVakoo: (callback)=>

    async.waterfall(
      [
        Vakoo.Utils.asyncLog @logger.info, "Install vakoo"
        async.apply Vakoo.Utils.spawnProcess, "npm", ["i", "--save", "vakoo"]
        Vakoo.Utils.asyncSkip
        async.apply Vakoo.Static.getFileContent, Vakoo.c.PATH_PACKAGE_JSON
        async.asyncify Vakoo.Utils.objectify
        (packageInfo, taskCallback)->

          packageInfo.dependencies.vakoo = packageInfo.dependencies.vakoo.split(".")[0...-1].join(".") + ".*"

          taskCallback null, packageInfo

        async.asyncify Vakoo.Utils.jsonify
        async.apply Vakoo.Static.setFileContent, Vakoo.c.PATH_PACKAGE_JSON
        Vakoo.Utils.asyncLog @logger.info, "Vakoo successfully installed"
      ]
      callback
    )

module.exports = Invoker