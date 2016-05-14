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
      .description "create and initialize Vakoo application"
      .option "-e, --env [env]", "List of environment names. Ex: dev,test,stable"
      .action @init

    program.parse process.argv

  init: (name = Vakoo.Static.getCwdFolderName(), {env})=>

    name = _.string.replaceAll(_.string.slugify(name), "-", "_")

    env ?= Vakoo.c.ENV_DEFAULT

    env = env.split(",")

    async.waterfall(
      [
        Vakoo.Utils.asyncLog @logger.info, "Create application `#{name}` with env `#{env}`"
#        async.apply Vakoo.Utils.generatePackageInfo, name

#        @installVakoo

        Vakoo.Utils.asyncLog @logger.info, "Create folder(s)"

        async.apply async.each, [Vakoo.c.PATH_CONFIGS, Vakoo.c.PATH_CONTROLLERS], Vakoo.Static.createFolderIfNotExists

        Vakoo.Utils.asyncLog @logger.info, "Create configs for each env"

        async.apply async.each, env, (env, done)-> new Vakoo.Creator({env}).createConfigFile done

      ]
      (err)=>
        @logger.error err if err
        process.exit()
    )

  @installVakoo: (callback)=>

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