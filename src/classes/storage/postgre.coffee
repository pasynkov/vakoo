pg = require "pg"
builder = require "mongo-sql"
_ = require "underscore"
_.string = require "underscore.string"
async = require "async"

TYPE_CREATE_TABLE = "create-table"
TYPE_SELECT = "select"
TYPE_INSERT = "insert"
TYPE_DELETE = "delete"

class PostgreTable

  constructor: (@connection, @name)->

  find: ([query] ..., callback)=>

    options =
      type: TYPE_SELECT
      table: @name
      where: query

    sql = builder.sql(options).toString()

    @connection.execute sql, callback

  insert: ([object, params]..., callback)=>

    options =
      type: TYPE_INSERT
      table: @name
      values: object

    query = builder.sql(options)

    @connection.execute query.toString(), query.values, callback

  remove: (query, callback)=>

    options =
      type: TYPE_DELETE
      table: @name
      where: query

    query = builder.sql(options)

    @connection.execute query.toString(), query.values, (err)-> callback err

  delete: (query, callback)=>

    @remove query, callback


class Postgre

  constructor: (@_config, @name = "main")->

    @logger = new Vakoo.Logger {
      label: "Postgre#{_.string.classify @name}"
    }

    @config =
      host: @_config.host or "localhost"
      username: @_config.username
      password: @_config.password
      database: @_config.database
      port: @_config.port or 5432

  isMain: => @_config.isMain is true

  #TODO autoreconnect
  connect: (callback)=>

    connString = "postgres://#{@config.username}:#{@config.password}@#{@config.host}:#{@config.port}/#{@config.database}"

    @client = new pg.Client connString

    @client.connect (err)=>

      if err
        @logger.error "Connection failed with err: `#{err}`"
        callback err, @
      else
        @logger.info "Connected successfully"
        callback null, @

  createMigrationCollectionIfNotExists: (callback)=>

    async.each(
      @getAvailableConnections()
      (conn, done)=>

        query = builder.sql {
          type: TYPE_CREATE_TABLE
          table: Vakoo.c.STORAGE_MIGRATIONS_COLLECTION
          ifNotExists: true
          definition:
            id:
              type: "int"
              notNull: true
              unique: true

            name:
              type: "text"
              notNull: true
        }

        conn.execute query.toString(), (err)-> done err

      callback
    )

  getAvailableConnections: =>

    if @isMain()

      names = _.chain(@)
      .values()
      .filter (prop)=> prop instanceof Postgre
      .value()

      if _.isEmpty(names)
        names = [@]

      names

    else [@]

  getExistsMigrations: (callback)=>

    async.map(
      @getAvailableConnections()
      (conn, done)->

        conn.collection(Vakoo.c.STORAGE_MIGRATIONS_COLLECTION).find done

      (err, result)=>
        return callback err if err

        callback null, _.object(
          _.map @getAvailableConnections(), ({name})-> name
          result
        )
    )

  appendToMigrationsTable: (id, name, callback)=>

    @collection(Vakoo.c.STORAGE_MIGRATIONS_COLLECTION).insert {
      id
      name
    }, (err)-> callback err

  removeFromMigrationsTable: (id, callback)=>

    @collection(Vakoo.c.STORAGE_MIGRATIONS_COLLECTION).remove {id}, (err)-> callback err

  table: (name)=>
    new PostgreTable @, name

  collection: (name)=>
    @table name

  execute: ([query, values] ... , callback)=>

    @client.query query, values, (err, result)->
      return callback err if err

      callback null, result.rows



module.exports = Postgre