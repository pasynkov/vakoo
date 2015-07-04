class Context

  constructor: (@requester, @responser, @controllerName, @action)->

    @logger = vakoo.logger.context

    @logger.info "incoming request to `#{@requester.url}`. Run controller `#{@controllerName}` with action `#{@action}`"

module.exports = Context