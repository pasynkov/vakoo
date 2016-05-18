class WebContext

  constructor: (@requester, @responser, @controllerName, @action)->

  getAction: -> @action or @requester.params.action

module.exports = WebContext