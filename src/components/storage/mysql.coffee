
_ = require "underscore"

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
    query = build(options).toString()
    callback null, query

  execute: (query, callback)=>
    @client.query query, callback


module.exports = Mysql