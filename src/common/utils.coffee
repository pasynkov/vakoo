{spawn} = require "child_process"
async = require "async"
readline = require "readline"
_ = require "underscore"

class Utils

  constructor: ->

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

          console.log requestKeys

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

module.exports = Utils