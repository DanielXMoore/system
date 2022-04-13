require "/setup"

Bindable = require "/lib/bindable"
MountFS = require "/lib/fs/mount"
PkgFS = require "/lib/fs/pkg"

testPkg =
  source:
    "hello.coffee":
      content: "alert hello"
    "test/wat.js":
      content: "assert(wat);"

testPkg2 =
  source:
    "yo.coffee":
      content: "alert 'ayyy'"

describe "Mount FS", ->
  it "should mount a filesystem", ->
    fs = MountFS()

    fs.mount("/pkg/", PkgFS(testPkg))

    fs.read("/pkg/hello.coffee")
    .then (blob) ->
      blob.text()
    .then (src) ->
      assert.equal src, "alert hello"

  it "should mount on top of previous path", ->
    fs = MountFS()

    fs.mount("/pkg/", PkgFS(testPkg))
    fs.mount("/pkg/", PkgFS(testPkg2))

    fs.read("/pkg/yo.coffee")
    .then (blob) ->
      blob.text()
    .then (src) ->
      assert.equal src, "alert 'ayyy'"

      fs.list('/pkg/')
      .then (files) ->
        assert.equal files.length, 1
        assert.equal files[0].path, "/pkg/yo.coffee"

        fs.mount("/pkg/", PkgFS(testPkg))
        fs.mount("/pkg/", PkgFS(testPkg))

        fs.list('/pkg/')
        .then (files) ->
          assert.equal files.length, 2
          assert.equal files[1].path, "/pkg/hello.coffee"

  it "should accept text strings in write method and save them with the proper media type passing options through", ->
    fs = MountFS()

    file = undefined
    opt = undefined
    fs.mount "/pkg/",
      write: (path, blob, options) ->
        file = blob
        opt = options
        Promise.resolve()
      read: (path) ->
        Promise.resolve file
      on: ->

    fs.write "/pkg/hey.js", "alert('hey');", cacheControl: 86400
    .then ->
      fs.read("/pkg/hey.js")
    .then (blob) ->
      assert.equal blob.type, "text/javascript; charset=utf-8"
      assert.equal opt.cacheControl, 86400

  it "should pass through calls to `clearCache`", ->
    fs = MountFS()

    called = false
    mock =
      clearCache: ->
        called = true

    Bindable null, mock

    fs.mount "/", mock

    fs.clearCache()
    assert called

  it.skip "should list contents of mounted subfolders", ->
    fs = MountFS()

    mock =
      list: ->
        Promise.resolve [{
          path: "a.txt"
        }, {
          path: "b.txt"
        }]

    Bindable null, mock

    fs.mount "/game/", mock
    fs.mount "/", mock

    fs.list "/"
    .then (results) ->
      assert.equal results.length, 4
