path = require "path"
_ = require "underscore"
_.string = require "underscore.string"
async = require "async"

TYPE_CONTROLLER = "controller"
TYPE_CONTROLLER_SHORT = "c"
TYPE_INITIALIZER = "initializer"
TYPE_INITIALIZER_SHORT = "i"
TYPE_TIMER = "timer"
TYPE_TIMER_SHORT = "t"
TYPE_MIGRATION = "migration"
TYPE_MIGRATION_SHORT = "m"
TYPE_SCRIPT = "script"
TYPE_SCRIPT_SHORT = "s"
TYPE_QUEUE = "queue"
TYPE_QUEUE_SHORT = "q"
TYPE_BATCH = "batch"
TYPE_BATCH_SHORT = "b"

class Creator

  constructor: ({@env, @envs, @mysql, @mongo, @postgre, @conn, @path})->

    @logger = new Vakoo.Logger {
      label: "Creator"
    }

  createByType: (type, name, callback)=>

    type = type.toLowerCase()

    if type in [TYPE_CONTROLLER, TYPE_CONTROLLER_SHORT]
      @createController name, callback
    else if type in [TYPE_INITIALIZER, TYPE_INITIALIZER_SHORT]
      @createInitializer name, callback
    else if type in [TYPE_TIMER, TYPE_TIMER_SHORT]
      @createTimer name, callback
    else if type in [TYPE_MIGRATION, TYPE_MIGRATION_SHORT]
      @createMigration name, callback
    else if type in [TYPE_SCRIPT, TYPE_SCRIPT_SHORT]
      @createScript name, callback
    else if type in [TYPE_QUEUE, TYPE_QUEUE_SHORT]
      @createQueue name, callback
    else if type in [TYPE_BATCH, TYPE_BATCH_SHORT]
      @createBatch name, callback
    else
      callback "Not available module type `#{type}`"

  createController: (name, callback)=>

    @createModule name, Vakoo.c.PATH_CONTROLLERS, TYPE_CONTROLLER, false, callback

  createQueue: (name, callback)=>

    @createModule name, Vakoo.c.PATH_QUEUES, TYPE_QUEUE, false, callback

  createBatch: (name, callback)=>

    @createModule name, Vakoo.c.PATH_BATCHES, TYPE_BATCH, false, callback

  createInitializer: (name, callback)=>

    @createModule name, Vakoo.c.PATH_INITIALIZERS, TYPE_INITIALIZER, true, callback

  createTimer: (name, callback)=>

    @createModule name, Vakoo.c.PATH_TIMERS, TYPE_TIMER, true, callback

  createMigration: (name, callback)=>

    @conn ?= "main"

    if not @mysql and not @mongo and not @postgre
      return callback "Need type of migration. --mongo or --mysql or --postgre."


    if @mysql
      migrationPath = Vakoo.c.PATH_MIGRATIONS_MYSQL
    else if @mongo
      migrationPath = Vakoo.c.PATH_MIGRATIONS_MONGO
    else if @postgre
      migrationPath = Vakoo.c.PATH_MIGRATIONS_POSTGRE

    time = Math.round(_.now() / 1000)

    name = time + "_" + name

    async.waterfall(
      [
        async.apply Vakoo.Static.createFolderIfNotExists, Vakoo.c.PATH_MIGRATIONS
        async.apply Vakoo.Static.createFolderIfNotExists, migrationPath
        async.apply @createModule, name, migrationPath, TYPE_MIGRATION, false, {connectionName: @conn}
      ]
      callback
    )

  createScript: (name, callback)=>

    @createModule(
      name
      if @path then Vakoo.Static.resolveFromCwd(@path) else Vakoo.c.PATH_SCRIPTS
      TYPE_SCRIPT
      false
      callback
    )

  createModule: ([name, folder, type, addToConfig, params]..., callback)=>

    params ?= {}

    fileName = Vakoo.Utils.fileSlugify(name)
    newFilePath = folder + Vakoo.c.PATH_SEPARATOR + fileName + Vakoo.c.EXT_COFFEE

    async.waterfall(
      [
        async.apply Vakoo.Static.createFolderIfNotExists, folder
        async.apply Vakoo.Static.getErrIfExists, newFilePath
        async.apply @getTemplate, type
        (template, taskCallback)->
          taskCallback null, template _.defaults({
            name: _.string.classify(name).replace /[0-9]/g, ""
          }, params)
        async.apply Vakoo.Static.setFileContent, newFilePath
        #todo remove addToConfig param
#        if addToConfig then async.apply(@addToConfigs, type, fileName) else async.asyncify(->)
      ]
      callback
    )

  addToConfigs: (type, fileName, callback)=>

    async.each(
      @envs
      async.apply @addToConfig, type, fileName
      callback
    )

  addToConfig: (field, fileName, env, callback)=>

    params = require Vakoo.c.PATH_CONFIGS + Vakoo.c.PATH_SEPARATOR + env

    params[field + "s"] ?= []

    params[field + "s"].push @createConfigItem(field, fileName)

    @createConfigFileByParams env, params, callback

  createConfigItem: (type, file)=>

    if type is TYPE_INITIALIZER
      file
    else if type is TYPE_TIMER
      {
        file
        time: "* * * * * *"
      }



  createConfigFile: (callback)=>

    @createConfigFileByParams @env, {
      storage: {}
      web: {}
      loggers: {}
      initializers: []
      timers: []
      pm2: []
    }, callback

  createConfigFileByParams: (env, params, callback)=>

    params.name = _.string.classify env
    params = _.mapObject params, (val)-> if _.isString(val) then val else JSON.stringify(val)

    async.waterfall(
      [
        async.apply @getTemplate, "config"
        (template, taskCallback)-> taskCallback null, template(params)
        async.apply Vakoo.Static.setFileContent, Vakoo.c.PATH_CONFIGS + Vakoo.c.PATH_SEPARATOR + env + Vakoo.c.EXT_COFFEE
      ]
      callback
    )

  getTemplate: (name, callback)=>

    Vakoo.Static.getTemplate path.resolve(__dirname, "../templates/", name + ".hbs"), callback

  getHelpText: =>

    console.log "  Types:"
    console.log()
    console.log "    controller (c)   create Controller"
    console.log "    initializer (i)  create Initializer"
    console.log "    timer (t)        create Timer"
    console.log "    migration (m)    create Migration"
    console.log "    env (e)          create Config"
    console.log "    script (s)       create Script"
    console.log "    queue (q)        create Queue"
    console.log "    batch (b)        create Batch"
    console.log()
    console.log()

    console.log "  Examples:"
    console.log()
    console.log "    $ vakoo create controller some_controller_name"
    console.log "    $ vakoo create t SomeInitializerName"
    console.log "    $ vakoo create script -p classes SomeScriptName"
    console.log "    $ vakoo create migraion --mysql migration_name"
    console.log "    $ vakoo create i -e test InitializerForTestEnv"
    console.log "    $ vakoo create c Api Static"
    console.log()

module.exports = Creator