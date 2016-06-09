pg = require "pg"
builder = require "mongo-sql"
_ = require "underscore"
_.string = require "underscore.string"
async = require "async"

TYPE_CREATE_TABLE = "create-table"
TYPE_SELECT = "select"
TYPE_INSERT = "insert"
TYPE_DELETE = "delete"
TYPE_DROP = "drop-table"
TYPE_ALTER = "alter-table"
TYPE_UPDATE = "update"

class PostgreTable

  constructor: (@connection, @name)->

  find: ([query, columns, joins, groupBy, order] ..., callback)=>

    order ?= "id desc"

    options =
      type: TYPE_SELECT
      table: @name
      where: query
      columns: columns
      joins: joins
      order: order

    if groupBy
      options.groupBy = groupBy

    query = builder.sql(options)

    @connection.execute query.toString(), query.values, callback

  count: ([where]..., callback)=>

    where ?= {}

    @complicatedFindOne where, {
      columns: [
        type: "count"
        as: "count"
        expression: "id"
      ]
    }, (err, {count})->
      callback err, +count


  complicatedInsert: (options = {}, callback)=>

    options.type = TYPE_INSERT
    options.table = @name

    query = builder.sql(options)

    @connection.execute query.toString(), query.values, callback

  complicatedFind: (where = {}, options = {}, callback)=>

    options.type = TYPE_SELECT
    options.table = @name
    options.where = where

    query = builder.sql(options)

    @connection.execute query.toString(), query.values, callback

  complicatedFindOne: (query = {}, options = {}, callback)=>

    options.limit = 1
    options.offset = 0

    @complicatedFind query, options, (err, rows)->
      callback null, rows?[0]

  findOne: ([query] ..., callback)=>

    @find query, ["*"], [], null, "", (err, rows)->

      return callback err if err

      callback null, rows[0]

  insert: ([object, params]..., callback)=>

    if _.isNull(object.id)
      object = _.omit(object, "id")

    options =
      type: TYPE_INSERT
      table: @name
      values: object
      returning: ["id"]

    query = builder.sql(options)

    @connection.execute query.toString(), query.values, (err, rows)->
      return callback err if err

      callback null, _.defaults(rows[0], object)

  insertBatch: (values, callback)=>

    options =
      type: TYPE_INSERT
      table: @name
      values: values

    query = builder.sql(options)

    @connection.execute query.toString(), query.values, (err)-> callback err

  upsert: (object, conflict, callback)=>

    if _.isNull(object.id)
      object = _.omit(object, "id")

    options =
      type: TYPE_INSERT
      table: @name
      values: object

    query = builder.sql(options)
    queryString = query.toString()

    for conflictKey, vals of conflict
      upsertStr = " ON CONFLICT (#{conflictKey}) DO UPDATE SET "
      upserts = []
      vals.target ?= []
      vals.excluded ?= []
      for key in vals.target
        upserts.push "#{key} = TARGET.#{key}"
      for key in vals.excluded
        upserts.push "#{key} = EXCLUDED.#{key}"
      queryString += upsertStr + upserts.join(", ") + " RETURNING id"

#
#    for key in conflict.target
#      upserts.push " ON CONFLICT (#{key}) DO UPDATE SET #{key} = TARGET.#{key}"
#
#    for key in conflict.excluded
#      upserts.push " ON CONFLICT (#{key}) DO UPDATE SET #{key} = EXCLUDED.#{key}"

    @connection.execute queryString, query.values, (err)->
      callback err

  remove: ([query]...,callback)=>

    query ?= {}

    options =
      type: TYPE_DELETE
      table: @name
      where: query

    query = builder.sql(options)

    @connection.execute query.toString(), query.values, (err)-> callback err

  delete: ([query]...,callback)=>

    @remove query, callback

  create: (definition, callback)=>

    query = builder.sql {
      type: TYPE_CREATE_TABLE
      table: @name
      ifNotExists: true
      definition
    }

    @connection.execute query.toString(), (err)-> callback err

  drop: ([cascade] ..., callback)=>

    cascade ?= true

    query = builder.sql {
      type: TYPE_DROP
      table: @name
      ifExists: true
      cascade
    }

    @connection.execute query.toString(), (err)-> callback err

  alter: (action, callback)=>

    query = builder.sql {
      type: TYPE_ALTER
      table: @name
      action: action
    }

    @connection.execute query.toString(), (err)-> callback err

  updateOne: (where, updates, callback)=>

    query = builder.sql {
      type: TYPE_UPDATE
      table: @name
      updates
      where
      returning: ["id"]
    }

    @connection.execute query.toString(), query.values, (err, rows)->
      return callback err if err

      callback null, _.defaults(rows[0], updates)

  update: (where, updates, callback)=>

    query = builder.sql {
      type: TYPE_UPDATE
      table: @name
      updates
      where
    }

    @connection.execute query.toString(), query.values, (err)-> callback err

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

        conn.collection(Vakoo.c.STORAGE_MIGRATIONS_COLLECTION).create {
            id:
              type: "int"
              notNull: true
              unique: true

            name:
              type: "text"
              notNull: true
          }, done

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

    @client.query query, values, (err, result)=>

      if err
        @logger.error "Execute query `#{query}` with values `#{values?.join(", ")}` failed with err: `#{err}`"
        return callback err

      callback null, result?.rows



module.exports = Postgre