_ = require "underscore"
_.string = require "underscore.string"
async = require "async"

class Migrator

  constructor: (@type, @databases)->

    @logger = new Vakoo.Logger {
      label: "Migrator"
    }

    @logger.info "Initialize `#{@type}` migrator with databases `#{@databases.join(", ")}`"

  invoke: (callback)=>

    async.each(
      @databases
      @invokeMigrationForDatabase
      callback
    )

  invokeMigrationForDatabase: (database, callback)=>

    @logger.info "Invoke migration for `#{database}`"

    if _.isEmpty(_app[database])
      @logger.warn "`#{database}` isnt available for migration"
      return callback()

    switch database
      when Vakoo.c.STORAGE_POSTGRE then migrationPath = Vakoo.c.PATH_MIGRATIONS_POSTGRE
      else return callback()

    async.waterfall(
      [
        _app[database].createMigrationCollectionIfNotExists

        async.apply async.parallel, [
          _app[database].getExistsMigrations
          async.apply Vakoo.Static.requireDirFiles, migrationPath
        ]

        ([existsMigrations, migrationFiles], taskCallback)->

          existsMigrationsIds = _.mapObject(
            existsMigrations
            (rows)-> _.map rows, ({id})-> id
          )

          needToUp = _.chain migrationFiles
          .pairs()
          .filter ([name, MigrationClass])->
            [id] = name.split "_"
            +id not in existsMigrationsIds[MigrationClass::connectionName]
          .object()
          .value()

          needToDown = _.chain(existsMigrations)
          .pairs()
          .map ([connectionName, rows])->

            _.map rows, ({id, name})-> {connectionName, id, name}

          .flatten()
          .filter ({connectionName, id})->

            _.find _.pairs(needToUp), ([name])-> +name.split("_")[0] <= +id

          .map ({connectionName, id, name})->
            filename = Vakoo.Utils.fileSlugify(id + "_" + name) + Vakoo.c.EXT_COFFEE

            if migrationFiles[filename] and migrationFiles[filename]::connectionName is connectionName
              [filename,migrationFiles[filename]]
            else false

          .compact()
          .object()
          .value()

          taskCallback null, {needToUp, needToDown}

        ({needToUp, needToDown}, taskCallback)=>

          async.waterfall(
            [
              async.apply @invokeMigrateDown, needToDown, database
              async.apply @invokeMigrateUp, needToUp, database
              async.apply @invokeMigrateUp, needToDown, database
            ]
            taskCallback
          )
      ]
      callback
    )

  invokeMigrateDown: (migrations, database, callback)=>

    @invokeMigrationsAction "migrateDown", migrations, database, callback

  invokeMigrateUp: (migrations, database, callback)=>

    @invokeMigrationsAction "migrateUp", migrations, database, callback

  invokeMigrationsAction: (action, migrations, database, callback)=>

    if _.isEmpty migrations
      return callback()

    sortedMigrations = _.sortBy _.pairs(migrations), ([name, MigrationClass])-> +name.split("_")[0]

    migrations = _.object sortedMigrations

    async.eachOfSeries(
      migrations
      (MigrationClass, name, done)=>

        MigrationClass::storage = database

        migration = new MigrationClass name

        migration[action] done

      callback
    )


module.exports = Migrator