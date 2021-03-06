fs = require "fs"
path = require "path"
Handlebars = require "handlebars"
_ = require "underscore"

class Static

  constructor: ->

  @getCwdFolderName: -> path.basename(process.cwd())

  @removeIfExists: (filePath, callback)->

    fs.exists filePath, (exists)->
      if exists
        fs.unlink filePath, callback
      else callback()

  @createFileIfNotExists: ([filePath, content] ..., callback)->

    Static.onExists(
      filePath
      -> callback()
      -> fs.appendFile filePath, content, callback
    )

  @getFileContent: (filePath, callback)->

    Static.onExists(
      filePath
      ->
        fs.readFile filePath, encoding: "utf8", callback
      callback
    )

  @setFileContent: (filePath, content, callback)->

    Static.removeIfExists filePath, (err)->
      return callback err if err
      fs.appendFile filePath, content, callback

  @onExists: (filePath, callback, errorCallback)->

    fs.exists filePath, (exists)->
      if exists
        callback()
      else
        errorCallback "File `#{filePath}` not exists."

  @getErrIfExists: (filePath, callback)->

    Static.onExists(
      filePath
      -> callback "File `#{filePath}` already exists"
      -> callback()
    )

  @createFolderIfNotExists: (folderPath, callback)->

    fs.exists folderPath, (exists)->
      if exists
        callback()
      else
        fs.mkdir folderPath, callback

  @getTemplate: (filePath, callback)->

    Static.getFileContent filePath, (err, content)->
      return callback err if err
      callback null, Handlebars.compile(content)

  @resolveFromCwd: (resolvingPath)->

    path.resolve process.cwd(), resolvingPath

  @getDirFiles: (dirPath, callback)->

    fs.readdir dirPath, callback

  @requireDirFiles: (dirPath, callback)->

    Static.getDirFiles dirPath, (err, files)->
      return callback err if err

      result = {}

      for file in files
        try
          result[file] = require Static.resolveFromCwd(dirPath + Vakoo.c.PATH_SEPARATOR + file)
        catch e
          return callback e.toString()

      callback null, result


  @getFileNameWithoutExt: (fileName)->

    ext = path.extname fileName
    path.basename fileName, ext

  @isLocal: =>

    vakooWorkingDirectory = path.resolve __dirname, "../.."

    vakooWorkingDirectory is Static.resolveFromCwd("node_modules/vakoo")

module.exports = Static