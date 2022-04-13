{JSDOM} = require("jsdom")
{window} = new JSDOM("")
{
  Blob
  FileList
  HTMLCollection
  Image
  Node
  document
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
  HTMLCollection
  Image
  Node
  PACKAGE
  assert
  document
  self
  window
}
