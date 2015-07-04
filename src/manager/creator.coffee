
handlebars = require "handlebars"
async = require "async"
_ = require "underscore"

Static = require "../classes/static"
Path = require "path"

Handlebars = require "handlebars"

class Creator

  constructor: (@type, @name, @storage)->

    @logger = manager.getLogger "VakooCreator"

    if @storage not in ["mongo", "mysql"]
      return @logger.error "Unkown storage `#{@storage}`"

    @static = new Static

  create: ->

    if @type is "migration"
      return @createMigration()

  createMigration: ->

    @logger.info "Start create migration `#{@name}`"


    async.waterfall(
      [
        async.apply @static.readFile, Path.join(__dirname, "..","scaffold/migration.hbs")
        (fileContent, taskCallback)=>
          template = handlebars.compile fileContent

          className = _.map(
            @name.split "_"
            (part)->
              return part[0].toUpperCase() + part[1...].toLocaleLowerCase()
          ).join ""

          taskCallback null, template({name: className, storage: @storage})

        (content, taskCallback)=>

          fileName = "#{Math.round(new Date().getTime() / 1000)}_#{@name}.coffee"

          @static.createFile "./migrations/#{fileName}", content, taskCallback


      ]
      (err)=>
        if err
          @logger.error "Failed with error `#{err}`"
        else
          @logger.info "Successfully"
    )


module.exports = Creator


