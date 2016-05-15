Invoker = require "./invoker"
Logger = require "../modules/logger"
Utils = require "../common/utils" #todo fix this
Static = require "../common/static" #todo fix this
Creator = require "./creator"
Constants = require "../constants"
Application = require "./application"
Configurator = require "../classes/configurator"
Web = require "../classes/web/web"
WebServer = require "../classes/web/server"
WebContext = require "../classes/web/context"

Controller = require "../extenders/controller"

Vakoo =
  package: require "../../package.json"
  Invoker: Invoker
  Logger: Logger
  Utils: Utils
  Static: Static
  Creator: Creator
  Application: Application
  Configurator: Configurator
  Web: Web
  WebServer: WebServer
  WebContext: WebContext
  Controller: Controller

Vakoo.c = new Constants Vakoo

module.exports = Vakoo