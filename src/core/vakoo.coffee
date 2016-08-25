Invoker = require "./invoker"
Logger = require "../modules/logger"
Utils = require "../common/utils" #todo fix this
Static = require "../common/static" #todo fix this
Creator = require "./creator"
Constants = require "../constants"
Application = require "./application"
Configurator = require "../classes/configurator"
Initializer = require "../extenders/initializer"
Timer = require "../extenders/timer"
Queue = require "../extenders/queue"
Batch = require "../extenders/batch"

Web = require "../classes/web/web"
WebServer = require "../classes/web/server"
WebContext = require "../classes/web/context"

Storage = require "../classes/storage/storage"
Mysql = require "../classes/storage/mysql"
Mongo = require "../classes/storage/mongo"
Redis = require "../classes/storage/redis"
Postgre = require "../classes/storage/postgre"
Elastic = require "../classes/storage/elastic"
Migration = require "../extenders/migration"
Migrator = require "../core/migrator"

Config = require "../extenders/config"

Controller = require "../extenders/controller"

Vakoo =
  package: require "../../package.json"
  Invoker: Invoker
  Logger: Logger
  _Logger: Logger
  Utils: Utils
  _Utils: Utils
  Static: Static
  Creator: Creator
  Application: Application
  Configurator: Configurator
  Web: Web
  WebServer: WebServer
  WebContext: WebContext
  _WebContext: WebContext
  Controller: Controller
  Storage: Storage
  Mysql: Mysql
  Mongo: Mongo
  Redis: Redis
  _Redis: Redis
  Postgre: Postgre
  _Postgre: Postgre
  Elastic: Elastic
  _Elastic: Elastic
  Migration: Migration
  Migrator: Migrator
  Initializer: Initializer
  Timer: Timer
  Queue: Queue
  _Queue: Queue
  Batch: Batch
  _Batch: Batch
  Config: Config
  _Config: Config
  invoke: ->

    window = global
    window.Vakoo = Vakoo

    new Invoker

Vakoo.c = new Constants Vakoo

module.exports = Vakoo