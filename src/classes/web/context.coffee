_ = require "underscore"

class WebContext

  constructor: (@requester, @responser, @controllerName, @action, @subAction)->

    @logger = new Vakoo.Logger {
      label: "WebContext"
    }

    @request =
      body: @requester.body
      query: @requester.query
      params: @requester.params
      method: @requester.method
      url: @requester.url
      headers: @requester.headers

    if _app.web.server.config.allowOrigin
      if _app.web.server.config.allowOrigin is true
        @allowOrigin()
      else if _.isArray(_app.web.server.config.allowOrigin)
        @allowOrigin _app.web.server.config.allowOrigin[0], _app.web.server.config.allowOrigin[1]

    @logger.info "Request: #{@requester.method}: #{@requester.url}. Run with `#{@controllerName}.#{@action}#{if @subAction then "." + @subAction else ""}`"

  getPathToRewritable: -> _.last __filename.split "src/"

  getAction: -> @action or @request.params.action or @request.query.action

  getSubAction: -> @subAction or @request.method

  allowOrigin: (origin = @request.headers.origin, methods = ["POST", "GET", "PUT", "DELETE", "PATCH", "OPTIONS"])->

    @responser.header "Access-Control-Allow-Origin", origin
    @responser.header "Access-Control-Allow-Credentials", "true"
    @responser.header "Access-Control-Allow-Headers", "Content-Type"
    @responser.header "Access-Control-Allow-Methods", methods.join(", ")

  sendResult: (err, data)=>

    if err
      @responser.statusCode = 404

    @responser.send err or data

  pong: (err)=> @sendResult err

module.exports = WebContext