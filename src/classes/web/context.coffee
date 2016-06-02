class WebContext

  constructor: (@requester, @responser, @controllerName, @action)->

    @request =
      body: @requester.body
      query: @requester.query
      params: @requester.params

  getAction: -> @action or @requester.params.action

  allowOrigin: (origin)->

    @responser.header "Access-Control-Allow-Origin", origin
    @responser.header "Access-Control-Allow-Headers", "Content-Type"
    @responser.header "Access-Control-Allow-Methods", "POST, GET, PUT, DELETE, OPTIONS"

  sendResult: (err, data)=>

    if err
      @responser.statusCode = 404

    @responser.send err or data

module.exports = WebContext