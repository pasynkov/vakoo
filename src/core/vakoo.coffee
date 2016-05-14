Invoker = require "./invoker"
Logger = require "../modules/logger"
Utils = require "../common/utils" #todo fix this
Static = require "../common/static" #todo fix this
Creator = require "./creator"
Constants = require "../constants"


Vakoo =
  package: require "../../package.json"
  Invoker: Invoker
  Logger: Logger
  Utils: Utils
  Static: Static
  Creator: Creator

Vakoo.c = new Constants Vakoo

module.exports = Vakoo