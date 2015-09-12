
_ = require "underscore"

mysql = require "mysql"
build = require("mongo-sql").sql

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





class Mysql

  constructor: (@name, @config)->

    @logger = vakoo.logger.mysql

    @config = _.defaults @config, vakoo.constants.DEFAULT_MYSQL_CONFIG

    @client = mysql.createConnection @config


  connect: (callback)=>

    @client.connect (err)=>
      if err

        @logger.error "`#{@name}` connection failed with error: `#{err}`"

      else

        @logger.info "`#{@name}` connected successfully"

      callback err

  table: (name)=>
    new MysqlTable @, name

  collection: (name)=>
    @table name

  buildQuery: (options, callback)=>
    query = build(options).toQuery()
    console.log query
    return
    callback null, query

  execute: (query, callback)=>
    @client.query query, callback


module.exports = Mysql