Vakoo = require "./src/vakoo"

global.vakoo = new Vakoo

vakoo.initialize (err)->
  if err
    vakoo.logger.main.error err
  else
    vakoo.logger.main.info "Vakoo started successfully"