async = require "async"
_ = require "underscore"

class Storage

  constructor: (@config)->

    @logger = new Vakoo.Logger {
      label: "Storage"
    }

  initialize: (callback)=>

    async.waterfall(
      [
        async.apply async.parallel, [
          @initializeMysql
        ]
      ]
      callback
    )

  initializeMysql: (callback)=>
    if (mysqlConfig = @validateConfig(@config.mysql, "mysql"))

      async.eachOf(
        mysqlConfig
        (config, name, done)=>

          console.log "mysql", name, config

        callback
      )

    else callback()

  validateConfig: (config, type)=>

    #todo validate logic
    if type is "mysql"

      if _.intersection(_.keys(config), ["host", "username", "password"]).length

        {main: config}

      else if _.isObject(config)

        if (mainConfig = @validateConfig(_.pick config, _.first(_.keys(config))))

          console.log "ADD MULTI CONFIG"

          return "aza"

        else false

      else false

    else false

module.exports = Storage