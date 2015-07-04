

Path = require "path"

async = require "async"
_ = require "underscore"

Static = require "../classes/static"
Vakoo = require "../vakoo"

class Migrator

  constructor: (@direction, @storage)->

    @logger = manager.getLogger "VakooMigrator"

    if @storage not in ["mongo", "mysql"]
      return @logger.error "Unkown storage type `#{@storage}`"

    global.vakoo = new Vakoo

    @storageConfig = _.pick(
      vakoo.configurator.storage
      @storage
    )

    @storageConfig.enable = true

    vakoo.configurator.storage = @storageConfig
    vakoo.configurator.web = null

    @static = new Static

  checkMigrationTable: (callback)=>

    async.waterfall(
      [
        (taskCallback)=>
          vakoo.mysql.client.query "SHOW TABLES", taskCallback
        (tables, ..., taskCallback)=>

          tables = _.map(
            tables
            (table)->
              return table["Tables_in_#{vakoo.mysql.config.database}"]
          )

          if "migrations" in tables
            taskCallback()
          else
            @createMigrationTable taskCallback

        (..., taskCallback)=>
          @logger.info "Table `migrations` is ok"
          taskCallback()

      ]
      callback
    )

  createMigrationTable: (callback)=>

    @logger.info "Table `migrations` not found, create table"

    vakoo.mysql.client.query """
      CREATE TABLE `migrations` (
        `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
        `added` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        `name` varchar(511) DEFAULT NULL,
        PRIMARY KEY (`id`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
    """, callback

  runMigrations: (migrations, callback)=>

    unless migrations.length
      @logger.info "Not found needed migrations"
      return callback()

    handlers = _.map(
      migrations
      (migration)=>
        return async.apply async.waterfall, [
            (taskCallback)=>
              @logger.info "Run `#{migration.name}` migration"
              taskCallback()
            migration.up
            (..., taskCallback)=>
              vakoo.mysql.client.query """
                INSERT INTO `migrations` SET name = '#{migration.name}'
              """, taskCallback
          ]
    )

    async.waterfall handlers, callback

  run: (callback)=>

    async.waterfall(
      [
        vakoo.initialize
        @checkMigrationTable
        (..., taskCallback)=>
          @static.readDir "./migrations", taskCallback
        (files, taskCallback)=>
          migrations = _.compact _.map(
            files
            (file)=>
              Migration = require Path.resolve(".", file)
              migration = new Migration
              if migration.storage is @storage
                migration.timestamp = +file.split("_")[0].split("/")[-1...][0]
                migration.name = file.split("_")[1...].join("_").replace ".coffee", ""
                migration
              else false
          )

          vakoo.mysql.client.query "SELECT * FROM migrations", (err, rows)->
            taskCallback err, rows, migrations

        (already, migrations, taskCallback)=>

          alreadyNames = _.map(
            already
            (row)->
              return row.name
          )

          @runMigrations _.reject(
            migrations
            (migration)->
              migration.name in alreadyNames
          ), taskCallback
      ]
      (err)=>
        if err
          @logger.error "Fail with err: `#{err}`"
        else
          @logger.info "Completed successfully"
        callback err
    )







module.exports = Migrator