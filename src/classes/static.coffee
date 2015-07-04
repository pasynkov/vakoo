fs = require "fs"
async = require "async"
mkdirp = require "mkdirp"

class Static

  constructor: ->


  readFile: (path, callback)=>
    async.waterfall(
      [
        async.apply @fileExists, path
        async.apply fs.readFile, path, encoding: "utf8"
      ]
      callback
    )

  readBuffer: (path, callback)=>

    async.waterfall(
      [
        async.apply @fileExists, path
        async.apply fs.readFile, path
      ]
      callback
    )


  fileExists: (path, callback)=>
    fs.exists path, (exists)->
      if exists
        callback()
      else
        callback "file `#{path}` isnt exists"

  createFile: (path, content, callback)=>
    fs.exists path, (exists)->
      if exists
        return callback "file already exists"

      mkdirp path.split("/")[...-1].join("/"), (err)->
        if err
          return callback err

        fs.writeFile path, content, callback



module.exports = Static