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
