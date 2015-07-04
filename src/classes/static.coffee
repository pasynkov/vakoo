fs = require "fs"
async = require "async"

class Static

  constructor: ->


  readFile: (path, callback)=>
    async.waterfall(
      [
        
      ]
      callback
    )

  fileExists: (path, callback)=>
    fs.fileExists path, callback

module.exports = Static