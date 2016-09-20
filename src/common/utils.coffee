{spawn} = require "child_process"
async = require "async"
readline = require "readline"
_ = require "underscore"

class Utils

  constructor: ->

  getPathToRewritable: -> _.last __filename.split "src/"

  @processQuestion: (question, callback)=>

    rl = readline.createInterface {
      input: process.stdin
      output: process.stdout
      terminal: false
    }

    rl.prompt true

    rl.question question, (answer)-> callback null, answer

  @spawnProcess: ([invoker, params]..., callback)->

    params ?= []

    proc = spawn invoker, params

    errorMessage = ""

    out = ""

    proc.stdout.on "data", (data)->
      out += data

    proc.stderr.on "data", (data)->
      errorMessage += data

    proc.on "error", callback

    proc.on "close", (code)->
      callback(
        if code is 0 then null else errorMessage
        out
      )

  @generatePackageInfo: (name, callback)=>

    packageInfo = _.defaults {name}, Vakoo.c.PACKAGE_INFO

    async.waterfall(
      [
        async.apply Vakoo.Static.createFileIfNotExists, Vakoo.c.PATH_PACKAGE_JSON, Utils.jsonify(packageInfo)
        async.apply Vakoo.Static.getFileContent, Vakoo.c.PATH_PACKAGE_JSON
        async.asyncify Utils.objectify
        (existsPackageInfo, taskCallback)->

          packageInfo = _.defaults existsPackageInfo, packageInfo

          requestKeys = _.without _.keys(packageInfo), "name", "dependencies"

          async.mapSeries(
            requestKeys
            (field, done)=>
              question = field
              if packageInfo[field]
                question += " (#{packageInfo[field]})"
              question += ": "

              Utils.processQuestion question, done

            (err, results)->
              return taskCallback err if err

              incomingResults = _.defaults _.object(requestKeys, results)

              for key of packageInfo
                if incomingResults[key]
                  packageInfo[key] = incomingResults[key]

              taskCallback null, packageInfo
          )

        async.asyncify Utils.jsonify
        async.apply Vakoo.Static.setFileContent, Vakoo.c.PATH_PACKAGE_JSON
      ]
      callback
    )

  @jsonify: (object)-> JSON.stringify object, "", "  "

  @objectify: (string, defaults = {})->

    try
      JSON.parse string
    catch e
      defaults

  @asyncSkip: (..., callback)-> callback()

  @asyncLog: (logMethod, message)->

    (..., callback)->
      logMethod message
      callback()

  @fileSlugify: (fileName)-> _.string.underscored fileName


  @rewriteCoreClasses: (logger)->

    _.chain Vakoo
    .keys()
    .filter (key)-> key[0] is "_"
    .map (key)-> [key[1...], ""]
    .object()
    .mapObject (value, className)->
      Vakoo.Static.resolveFromCwd("_vakoo/" + Vakoo[className]::getPathToRewritable())
    .pairs()
    .map ([className, pathToLocalClass])->
      try
        Class = require pathToLocalClass
        return [className, Class]
      catch e
        if e.code is "MODULE_NOT_FOUND"
          return null
        else
          throw new Error e
    .compact()
    .each ([className, Class])->
      logger.info "Rewrite by local class `#{className}`"
      Vakoo[className] = Class
    .value()


module.exports = Utils