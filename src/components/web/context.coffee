class Context

  constructor: (@requester, @responser, @controllerName, @action)->

    @logger = vakoo.logger.context

    @logger.info "incoming request to `#{@requester.url}`. Run controller `#{@controllerName}` with action `#{@action}`"

    @request =
      method: @requester.method
      path: @requester.path
      query: @requester.query
      url: @requester.url
      body: @requester.body
      ip: @requester.ip
      userAgent: @requester.headers['user-agent'] or ""
      headers: @requester.headers
      options: {}

    @response =
      code: 200
      data: null
      redirect: false

    @data =
    ## TODO: проверить, вроде как нигде не используется
      databaseName: null
      databaseType: null
      collectionName: null
      model: null
      query: null

  sendHtml: (err, html)=>

    if @response.redirect
      @logger.info "Redirect to `#{@response.redirect}`"
      return @responser.redirect @response.redirect

    @responser.send err or html

module.exports = Context