# We require the polyfill and the extensions, it is our convention
require "./lib/extensions"

# Launch demo if we are the published package (not a lib)
# if PACKAGE.name is "ROOT"
#   require "./demo"

global.PACKAGE =
  config: require "../pixie.cson"


###*
descripbing nsomp jsdoct
###
module.exports = require "./lib/exports"
