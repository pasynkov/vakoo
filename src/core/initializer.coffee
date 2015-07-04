

_ = require "underscore"
async = require "async"

Storage = require "../components/storage/storage"
Web = require "../components/web/web"

class Initializer

  constructor: (callback)->

    @initializers = []

    if vakoo.configurator.storage?.enable
      vakoo.storage = new Storage
      @addInitializer vakoo.storage.connect

    if vakoo.configurator.web?.enable
      vakoo.web = new Web
      @addInitializer vakoo.web.start


  addInitializer: (initializer)=>
    @initializers.push initializer

  run: (callback)=>

    async.waterfall(
      @initializers
      callback
    )



module.exports = Initializer