


constants = {
  DEFAULT_ENVIRONMENT: "default"
  CONFIG_DIR: "config"
  CONTROLLERS_DIR: "controllers"
  PROJECT_CONFIG_FILE: "project"
  DEFAULT_LOGGERS: [
    "main"
    "redis"
    "mongo"
    "mysql"
    "initializer"
    "storage"
    "web"
    "context"
    "cron"
  ]
  DEFAULT_LOGGER_CONFIG:
    console:
      level: "info"
      colorize: true
  DEFINED_STORAGES: [
    "redis"
    "mongo"
    "mysql"
  ]
  DEFAULT_REDIS_CONFIG:
    host: "127.0.0.1"
    port: 6379
  DEFAULT_MYSQL_CONFIG:
    host: "127.0.0.1"
    port: 3306
  DEFAULT_MONGO_CONFIG:
    host: "127.0.0.1"
    port: 27017
  ROUTER_FILE: "router"
}

module.exports = constants