# We require the polyfill and the extensions, it is our convention
require "./lib/polyfill.coffee"
require "./lib/extensions.coffee"

# Launch demo if we are the published package (not a lib)
# if PACKAGE.name is "ROOT"
#   require "./demo"

module.exports = require "./lib/exports.coffee"
