# We require the polyfill and the extensions, it is our convention
require "./lib/polyfill"
require "./lib/extensions"

# Launch demo if we are the published package (not a lib)
# if PACKAGE.name is "ROOT"
#   require "./demo"

module.exports = require "./lib/exports"
