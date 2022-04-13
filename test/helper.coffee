{JSDOM} = require("jsdom")
{window} = new JSDOM("")
{
  Blob
  FileList
  FileReader
  HTMLCollection
  Image
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
  Node
  PACKAGE
  assert
  document
  navigator
  opener
  parent
  self
  window
}
