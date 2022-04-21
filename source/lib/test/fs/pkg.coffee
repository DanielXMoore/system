PkgFS = require "../../fs/pkg"

require "../../extensions"

testPkg =
  source:
    "hello.coffee":
      content: "alert hello"
    "test/wat.js":
      content: "assert(wat);"
  distribution: {}

oldPersist = (pkg) ->
  # Persist entire pkg
  system.writeFile persistencePath, JSON.toBlob(pkg)

# old compile was system.compileFile

describe "Package FS", ->
  it "should read files", ->
    pfs = PkgFS testPkg

    pfs.read("hello.coffee")
    .then (blob) ->
      blob.text()
    .then (src) ->
      assert.equal src, "alert hello"

  it "should write files", ->
    persistCalled = false
    persist = -> persistCalled = true
    compileCalled = false
    compile = (blob) ->
      compileCalled = true
      blob.text()

    pfs = PkgFS testPkg,
      persist: persist
      compile: compile

    content = "alert('hey');"
    pfs.write "/yolo.js", new Blob([content])
    .then ->
      assert compileCalled
      assert persistCalled

      assert.equal testPkg.source["yolo.js"].content, content
      assert.equal testPkg.distribution["yolo"].content, content
