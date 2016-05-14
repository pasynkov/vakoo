winston = require "winston"

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

module.exports = Logger