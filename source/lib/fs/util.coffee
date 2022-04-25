###
Utility methods for manipulating and normalizing file system paths.
###

separator = "/"

normalizePath = (path) ->
  path.replace(/\/+/g, separator) # /// -> /
  .replace(/\/[^/]*\/\.\.(\/|$)/g, separator) # /base/something/.. -> /base/
  .replace(/\/(\.(\/|$))*/g, separator) # /base/. -> /base/

normalizePath2 = (path) ->
  stack = []
  path.split(separator).forEach (part) ->
    switch part
      when ".", ""
        ;# Skip
      when ".."
        if stack.length
          stack.pop()
        else
          throw new Error "No upper directory when normalizing '#{path}'"
      else
        stack.push part

  # Add leading and trailing slashes as necessary
  if path.startsWith '/'
    stack.unshift ''
  else if path.startsWith './' # Keep local paths
    stack.unshift '.'
  if path.match /\/\.{0,2}$/
    stack.push ''

  return stack.join(separator)

# By default throws an error when paths '../..' try go above the base path
# can be overridden by passing false as the third parameter.
absolutizePath = (base, relativePath, preventEscape=true) ->
  unless base.startsWith separator
    throw new Error "base path must be absolute"
  unless base.endsWith separator
    throw new Error "base path must be a directory"

  path = normalizePath "#{base}#{relativePath}"

  if preventEscape
    unless path.startsWith normalizePath base
      throw new Error "path escaped base directory (too many ../)"

  return path

allDirectories = /^.*\//

#
###*
@param path {string}
###
baseName = (path) ->
  path.replace(allDirectories, "")

#
###*
@param path {string}
###
extensionFor = (path) ->
  result = baseName(path).match /\.([^.]+)$/

  if result
    result[1] or ""
  else
    ""

# Only media types for editible text types that have a special meaning to the
# browser. html, css, js, json all require the proper content type header to
# work properly so we make sure to have the correct data. Also setting the
# charset to utf-8 which is the only one that we currently support.
mimes =
  css: "text/css"
  html: "text/html"
  js: "text/javascript"
  json: "application/json"
  md: "text/markdown"

textMediaType = (path) ->
  extension = extensionFor(path)
  type = mimes[extension] or "text/plain"

  "#{type}; charset=utf-8"

module.exports =
  absolutizePath: absolutizePath
  baseDirectory: (absolutePath="/") ->
    absolutePath.match(allDirectories)?[0]
  baseName: baseName
  extensionFor: extensionFor
  fileSeparator: separator
  isRelativePath:  (path) ->
    !!path.match /^.?.\//
  normalizePath: normalizePath
  normalizePath2: normalizePath2

  Ergonomics: (fs) ->
    # Wrap read with more ergonomic text file writing
    do (write=fs.write) ->
      fs.write = (path, stringOrBlob, args...) ->
        if typeof stringOrBlob is "string"
          blob = new Blob [stringOrBlob],
            type: textMediaType path
        else
          blob = stringOrBlob

        write.call(fs, path, blob, args...)

    return fs

  separator: separator
  textMediaType: textMediaType

  withoutExtension: (path) ->
    path.replace(/\.[^\.\/]*$/,"")

  withoutAllExtensions: (path) ->
    path.replace(/\.[^\/]*$/,"")
