"" # TOOD: CoffeeSense hack to move comment below var declarations
#@ts-ignore
require("css.escape")

{JSDOM} = require("jsdom")
{window} = new JSDOM("")
{
  Blob
  FileList
  FileReader
  HTMLCollection
  Image
  KeyboardEvent
  Node
  document
  navigator
  opener
  parent
  self
} = window

assert = require "assert"

# TODO: Read config from pixie.cson?
PACKAGE =
  config:
    cognito: {}

Object.assign global, {
  Blob
  FileList
  FileReader
  HTMLCollection
  Image
  KeyboardEvent
  Node
  PACKAGE
  assert
  crypto: require('crypto').webcrypto
  document
  navigator
  opener
  parent
  self
  window
}

Object.assign navigator,
  # stub clipboard API
  clipboard:
    writeText: -> Promise.resolve()

# Mock styl register
###* @type {(module: import("module"), filename: string) => void} ###
require.extensions[".styl"] = (module) ->
  module.exports = ""
  return

CoffeeScript = require "coffeescript"
fs = require "fs"
# Add CSON loader
###* @type {(module: import("module"), filename: string) => void} ###
require.extensions[".cson"] = (module, filename) ->
  src = fs.readFileSync(filename, 'utf8')
  js = "module.exports = " + CoffeeScript.compile src, bare: true

  module._compile(js, filename)
  return
