

_ = require "underscore"
async = require "async"

path = require "path"

Storage = require "../components/storage/storage"
Web = require "../components/web/web"

class Initializer

  constructor: (callback)->

    @initializers = []



    if vakoo.configurator.storage?.enable
      vakoo.storage = new Storage
      @addInitializer vakoo.storage.connect

    if vakoo.configurator.initializers
      for initializerScriptPath in vakoo.configurator.initializers
        InitializerScript = require path.resolve("initializers/#{initializerScriptPath}")
        @initializers.push InitializerScript

    if vakoo.configurator.web?.enable
      vakoo.web = new Web
      @addInitializer vakoo.web.start


    vakoo.classes = {}
    vakoo.classes.Static = require "../classes/static"


  addInitializer: (initializer)=>
    @initializers.push initializer

  run: (callback)=>

    async.waterfall(
      @initializers
      callback
    )



module.exports = Initializer