Vakoo = require "./src/vakoo"

new Vakoo (err)->
  if err
    vakoo.logger.main.error "Vakoo start failed with err: `#{err}`"
    console.log err.stack
  else
    vakoo.logger.main.info "Vakoo started successfully"