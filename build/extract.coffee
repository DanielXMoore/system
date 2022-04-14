{mkdir, writeFile} = require "fs/promises"
{dirname} = require "path"

pkg = require "./0.5.3.json"

Object.keys(pkg.source).forEach (key) ->
  dir = dirname(key)
  src = pkg.source[key].content

  if src.length
    await mkdir dir, recursive: true
    writeFile key, src
