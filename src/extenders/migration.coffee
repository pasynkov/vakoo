_ = require "underscore"
_.string = require "underscore.string"

class Migration

  constructor: (name)->

    [id, underscoredNameArr...] = name.split "_"

    @id = +id
    @name = _.string.classify(underscoredNameArr.join("_").replace(Vakoo.c.EXT_COFFEE, ""))

    @connection = _app[@storage][@connectionName] or _app[@storage]

    @logger = new Vakoo.Logger {
      label: "Migration#{@name}"
    }

  migrateUp: (callback)=>

    @type = "up"

    startTime = new Date()

    @logger.info "Invoke migrate up at #{startTime}"

    @up (err)=>

      endTime = new Date()

      seconds = Math.round((endTime.getTime() - startTime.getTime()) / 1000)

      if err
        @logger.error "Migration failed with err: `#{err}`"
        callback()
      else
        @logger.info "Migration successfully completed at #{endTime}. Executing with `#{seconds}s`"
        @connection.appendToMigrationsTable @id, @name, callback

  migrateDown: (callback)=>

    @type = "down"

    startTime = new Date()

    @logger.info "Invoke migrate down at #{startTime}"

    @down (err)=>

      endTime = new Date()

      seconds = Math.round((endTime.getTime() - startTime.getTime()) / 1000)

      if err
        @logger.error "Migration failed with err: `#{err}`"
        callback()
      else
        @logger.info "Migration successfully completed at #{endTime}. Executing with `#{seconds}s`"
        @connection.removeFromMigrationsTable @id, callback


  up: (callback)-> callback()

  down: (callback)-> callback()


module.exports = Migration