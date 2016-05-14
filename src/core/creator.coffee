path = require "path"
_ = require "underscore"
_.string = require "underscore.string"

class Creator

  constructor: ({@env})->

    @logger = new Vakoo.Logger {
      label: "Creator"
    }

  createConfigFile: (callback)=>

    @logger.info "Create `#{@env}` config file"

    @getTemplate "config", (err, template)=>
      return callback err if err

      name = _.string.classify @env

      params = {
        name
        storage: {}
        web: {}
        loggers: {}
        initializers: []
        timers: []
        pm2: []
      }

      params = _.mapObject params, (val)-> if _.isString(val) then val else Vakoo.Utils.jsonify(val)

      Vakoo.Static.setFileContent Vakoo.Static.resolveFromCwd(Vakoo.c.PATH_CONFIGS + "/" + @env + ".coffee"), template(params), callback

  getTemplate: (name, callback)=>

    Vakoo.Static.getTemplate path.resolve(__dirname, "../templates/", name + ".hbs"), callback

module.exports = Creator