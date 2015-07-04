


constants = {
  DEFAULT_ENVIRONMENT: "development"
  DEFAULT_CONFIG_SCOPE: "default"
  CONFIG_DIR: "config"
  CONTROLLERS_DIR: "controllers"
  PROJECT_CONFIG_FILE: "project"
  DEFAULT_LOGGERS: [
    "main"
    "redis"
    "mongo"
    "initializer"
    "storage"
    "web"
    "context"
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
  ROUTER_FILE: "router"
}

module.exports = constants