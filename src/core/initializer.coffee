

_ = require "underscore"
async = require "async"
CronJob = require("cron").CronJob

path = require "path"

Storage = require "../components/storage/storage"
Web = require "../components/web/web"

class Initializer

  constructor: (callback)->

    @initializers = []

    @logger = vakoo.logger.initializer

    if vakoo.configurator.storage?.enable
      vakoo.storage = new Storage
      @addInitializer vakoo.storage.connect

    if vakoo.configurator.initializers?.length

      @initializers.push @customInitializer

    if vakoo.configurator.crons?.length

      @initializers.push @startCrons

    if vakoo.configurator.web?.enable
      vakoo.web = new Web
      @addInitializer vakoo.web.start


    vakoo.classes = {}
    vakoo.classes.Static = require "../classes/static"

    @initialize callback


  addInitializer: (initializer)=>
    @initializers.push initializer

  initialize: (callback)=>

    async.waterfall(
      @initializers
      callback
    )

  customInitializer: (callback)=>

    @logger.info "Start initializers"

    index = 0
    invokeScript = =>
      if index < vakoo.configurator.initializers.length
        script = vakoo.configurator.initializers[index]
        @logger.info "Run `#{script}` initializer"
        Script = require path.resolve("initializers/#{script}")
        new Script ->
          index++
          invokeScript()
      else
        callback null
    invokeScript()

  startCrons: (callback)=>

    @logger.info "Start crons"
    cronLogger = vakoo.logger.cron

    index = 0
    invokeScript = =>
      if index < vakoo.configurator.crons.length
        task = vakoo.configurator.crons[index]
        @logger.info "Run `#{task.name}` cron"
        Script = require path.resolve("crons/#{task.script}")

        do (Script, task)=>

          cronLogger.info "Start `#{task.name}` cron-task. #{new Date()}"

          new CronJob {
            cronTime: task.time
            onTick: ->
              new Script ->
                cronLogger.info "Complete `#{task.name}` cron-task. #{new Date()}"
            start: true
          }

          index++
          invokeScript()

      else
        callback()
    invokeScript()


module.exports = Initializer