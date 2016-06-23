_ = require "underscore"
_.string = require "underscore.string"
CronJob = require("cron").CronJob

class Timer

  constructor: (@name, @time)->

    @logger = new Vakoo.Logger {
      label: "#{_.string.classify @name}Timer"
    }

    if @time

      @logger.info "Register with time `#{@time}`"

      @job = new CronJob {
        cronTime: @time
        onTick: @_invoke
        start: true
      }
    else

      @logger.warn "Skip registering timer without time"

  _invoke: =>

    @logger.info "Invoke at #{new Date}"
    @invoke (err)=>
      if err
        @logger.info "Invoke failed at #{new Date} with err: `#{err}`"
      else
        @logger.info "Invoke successfully completed at #{new Date}"


  invoke: (callback)-> callback()


module.exports = Timer