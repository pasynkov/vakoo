fs = require "fs"
async = require "async"
mkdirp = require "mkdirp"
Path = require "path"

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

  readDir: (dir, callback)=>
    fs.readdir dir, (err, files)=>
      if err
        callback err
      else
        returnFiles = []
        async.each(
          files
          (file, eCallback)=>
            filePath = Path.join(dir, file)
            fs.stat filePath, (err, stat)=>
              if err
                eCallback err
              else
                if stat.isDirectory()
                  @readDir filePath, (err, results)->
                    if err
                      eCallback err
                    else
                      returnFiles = returnFiles.concat results
                      eCallback()
                else if stat.isFile()
                  returnFiles.push filePath
                  eCallback()

          (err)->
            callback err, returnFiles
        )



module.exports = Static