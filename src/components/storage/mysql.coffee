
_ = require "underscore"

mysql = require "mysql"

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




module.exports = Mysql