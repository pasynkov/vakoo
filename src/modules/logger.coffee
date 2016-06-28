winston = require "winston"
_ = require "underscore"

class Logger extends winston.Logger

  constructor: ({label})->
    super {
      transports: [
        new winston.transports.Console {
          label
          level: "info"
          colorize: true
        }
      ]
    }

  getPathToRewritable: -> _.last __filename.split "src/"

module.exports = Logger