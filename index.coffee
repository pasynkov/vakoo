Vakoo = require "./src/core/vakoo"

if Vakoo.Static.isLocal()
  Vakoo.invoke()
else
  try
    require Vakoo.Static.resolveFromCwd "node_modules/vakoo/index"
  catch
    Vakoo.invoke()

