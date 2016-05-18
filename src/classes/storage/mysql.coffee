_ = require "underscore"
_.string = require "underscore.string"
async = require "async"

mysql = require "mysql"
#todo mysql support sapient here https://github.com/goodybag/mongo-sql/issues/121
buildOld = require("mongo-sql").sql
build = (query)->
  result = buildOld query
  {
  values: result.values
  toString: ->
    query = result.toString().replace /\$\d+/g, (str)->
      i = +str.substring(1) - 1
      val = result.values[ i ]
      return if typeof val is "string" then "'#{val}'" else val
    query = query.replace /\"/g, "`"
  }

class MysqlTable

  constructor: (@mysql, @tableName)->

  find: ([query] ..., callback)=>

    options =
      type: "select"
      table: @tableName
      where: query

    @mysql.buildQuery options, (err, sql)=>
      if err
        return callback err

      @mysql.execute sql, callback

  findOne: ([query] ..., callback)=>

    options =
      type: "select"
      table: @tableName
      where: query
      limit: 1

    @executeOptions options, (err, [row])=>
      callback err, row

  update: ([query, updates]..., callback)=>

    options =
      type: "update"
      table: @tableName
      updates: updates
      where: query

    @executeOptions options, (err, result)=>
      callback err

  remove: (query, callback)=>

    options =
      type: "delete"
      table: @tableName
      where: query

    @executeOptions options, (err, result)=>
      callback err

  delete: (query, callback)=>

    @remove query, callback

  insert: ([object, params]..., callback)=>

    options =
      type: "insert"
      table: @tableName
      values: object

    if params?.updateOnDuplicate
      return @mysql.buildQuery options, (err, sql)=>
        if err
          return err

        sql += " ON DUPLICATE KEY UPDATE "

        sql += _.map(
            params.updateOnDuplicate.set or []
          (field)->

            val = object[field]

            if _.isNaN(+val)
              val = "'#{val}'"
            "`#{field}` = #{val}"
        ).join(", ")

        if params.updateOnDuplicate.ignore
          sql += "`#{params.updateOnDuplicate.ignore}` = `#{params.updateOnDuplicate.ignore}`"

        @mysql.execute sql, callback

    @executeOptions options, (err, {insertId})=>
      callback err, insertId

  executeOptions: (options, callback)=>

    @mysql.buildQuery options, (err, sql)=>
      if err
        return callback err

      @mysql.execute sql, callback


CONN_ERR_NOT_FOUND = "ENOTFOUND"
CONN_ERR_ACCESS_DENIED = "ER_ACCESS_DENIED_ERROR"
CONN_ERR_CONNECTION_LOST = "PROTOCOL_CONNECTION_LOST"
CONN_ERR_FATAL_ERROR = "PROTOCOL_ENQUEUE_AFTER_FATAL_ERROR"
CONN_ERR_CONNECTION_RESET = "ECONNRESET"
CONN_ERR_CONNECTION_REFUSED = "ECONNREFUSED"

class Mysql

  constructor: (config, @name = "main")->

    @logger = new Vakoo.Logger {
      label: "Mysql#{_.string.classify @name}"
    }

    @connected = false

    @config =
      host: config.host or "localhost"
      user: config.username
      password: config.password
      database: config.database
      port: config.port or 3306
#      connectTimeout: config.connectTimeout or 10000

    @createClient()

  createClient: =>

    @client = mysql.createConnection @config
    @client.on "error", @errorHandler


  errorHandler: (err)=>

    if @isReconnectCode err?.code or err
      @logger.error "Spawn connection err: `#{err}`. Start reconnect scenario."
      @connected = false
      @invokeReconnect (err)=>

        unless @connected
          err ?= "Mysql cannot connecting."

        @connectCallback err

  connectCallback: (err)=>

    unless @_callbackCalled
      @_callbackCalled = true
      @_callback err

  connect: (@_callback)=>

    @doConnection (err)=>
      if err and @isReconnectCode err.code
        @client.emit "error", err.code
      else @connectCallback err

  doConnection: (callback)=>

    @client.connect (err)=>
      unless err
        @connected = true
        @logger.info "Connected successfully"

      callback err

  isReconnectCode: (code)=> code in [CONN_ERR_CONNECTION_LOST, CONN_ERR_CONNECTION_RESET, CONN_ERR_FATAL_ERROR, CONN_ERR_NOT_FOUND, CONN_ERR_CONNECTION_REFUSED]

  invokeReconnect: (callback)=>

    @logger.info "Invoke reconnect"

    interval = 500
    maxInterval = 10000
    times = 10000
    t = 0

    async.during(
      (run)=>

#        interval = interval * 2
#        if interval >= maxInterval
#          interval = maxInterval

        setTimeout(
          =>
            run null, t < times and not @connected
          interval
        )

      (done)=>

        console.log "tick"

        t++

        @close =>

          @doConnection (err)=>
            if err
              @logger.error "Spawn connection err: `#{err.code}`. Start reconnecting."
            done()

      callback
    )

  close: (callback)=>

    @client.end (err)=>

      @client.destroy() if err

      @createClient()

      callback()

  table: (name)=>
    new MysqlTable @, name

  collection: (name)=>
    @table name

  buildQuery: (options, callback)=>
    query = build(options).toString()
    callback null, query

  execute: (query, callback)=>
    @client.query query, (err, result)=>
      if err
        @logger.error err
      callback err, result


module.exports = Mysql