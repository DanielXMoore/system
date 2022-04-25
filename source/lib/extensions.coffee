{ deprecationWarning } = require "./util/index.coffee"

#
###*
Add some utility readers to the Blob API
@param file {Blob}
@param method {"readAsText" | "readAsArrayBuffer" | "readAsDataURL"}
###
promiseReader = (file, method) ->
  new Promise (resolve, reject) ->
    reader = new FileReader
    reader.onload = ->
      resolve reader.result
    reader.onerror = reject
    reader[method](file)

#
###*
@this {Blob}
###
readAsText = ->
  promiseReader(this, "readAsText")

#
###*
@this {Blob}
###
readAsArrayBuffer = ->
  promiseReader(this, "readAsArrayBuffer")

#
###*
@this {Blob}
###
readAsDataURL = ->
  promiseReader(this, "readAsDataURL")

#
###*
@this {Blob}
###
readAsJSON = ->
  @text()
  .then JSON.parse

Object.assign Blob::,
  readAsText: deprecationWarning "blob.readAsText -> blob.text", readAsText

  readAsArrayBuffer: deprecationWarning "blob.readAsArrayBuffer -> blob.arrayBuffer",
    readAsArrayBuffer

  readAsDataURL: deprecationWarning "blob.readAsDataURL -> blob.dataURL", readAsDataURL

  readAsJSON: deprecationWarning "blob.readAsJSON -> blob.json", readAsJSON

Blob::arrayBuffer ?= readAsArrayBuffer
Blob::dataURL ?= readAsDataURL
Blob::json ?= readAsJSON
Blob::text ?= readAsText

#
###*
@param path {string}
###
Blob::download = (path) ->
  url = URL.createObjectURL(this)
  a = document.createElement("a")
  a.href = url
  a.style.display = "none"
  a.download = path
  document.body.appendChild a # FF requires element to be attached to DOM
  a.click()
  a.remove()
  URL.revokeObjectURL(url)

###*
Load an image from a blob returning a promise that is fulfilled with the
loaded image or rejected with an error
@param blob {Blob}
###
#@ts-ignore TODO: Can't add fromBlob to global image var easily
Image.fromBlob = (blob) ->
  url = URL.createObjectURL(blob)

  new Promise (resolve, reject) ->
    img = new Image
    img.onload = ->
      URL.revokeObjectURL url
      resolve img
    img.onerror = (e) ->
      URL.revokeObjectURL url
      reject e

    img.src = url

# Extend JSON with toBlob method
JSON.toBlob ?= (object, mime="application/json") ->
  new Blob [JSON.stringify(object)], type: "#{mime}; charset=utf-8"

# HTML Extensions
HTMLCollection::forEach ?= Array::forEach
FileList::forEach ?= Array::forEach

module.exports = {}
