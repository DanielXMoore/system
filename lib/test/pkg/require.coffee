
# Load our latest require code for testing
# NOTE: This causes the root for relative requires to be at the root dir, not the test dir
requireSrc = "../../pkg/require2"
latestRequire = require(requireSrc).generateFor(PACKAGE)
sampleDir = "../../../data/pkg/samples/"

# TODO
describe.skip "require", ->
  it "should not exist globally", ->
    assert !global.require

  it "should be able to require a file that exists with a relative path", ->
    assert latestRequire("#{sampleDir}terminal")

  it "should get whatever the file exports", ->
    assert latestRequire("#{sampleDir}terminal").something

  it "should not get something the file doesn't export", ->
    assert !latestRequire("#{sampleDir}terminal").something2

  it "should throw a descriptive error when requring circular dependencies", ->
    assert.throws ->
      latestRequire("#{sampleDir}circular")
    , /circular/i

  it "should throw a descriptive error when requiring a package that doesn't exist", ->
    assert.throws ->
      latestRequire "does_not_exist"
    , /not found/i

  it "should throw a descriptive error when requiring a relative path that doesn't exist", ->
    assert.throws ->
      latestRequire "/does_not_exist"
    , /Could not find file/i

  it "should recover gracefully enough from requiring files that throw errors", ->
    assert.throws ->
      latestRequire "#{sampleDir}throws"

    assert.throws ->
      latestRequire "#{sampleDir}throws"
    , (err) ->
      !/circular/i.test err

  it "should cache modules", ->
    result = latestRequire("#{sampleDir}random")

    assert.equal latestRequire("#{sampleDir}random"), result

  it "should be able to require a JSON package object", ->
    SAMPLE_PACKAGE =
      entryPoint: "main"
      distribution:
        main:
          content: "module.exports = require('./other')"
        other:
          content: "module.exports = 'TEST'"

    result = latestRequire SAMPLE_PACKAGE

    assert.equal "TEST", result

  it "should be able to require something packaged with browserify", ->
    assert.equal latestRequire("#{sampleDir}browserified"), "coolio"

describe "package wrapper", ->
  it "should be able to generate a package wrapper recursively", ->
    pkgString = latestRequire.packageWrapper(PACKAGE, "global.r = require")

    Function(pkgString)()
    Function(r.packageWrapper(PACKAGE, "global.r2 = require"))()
    Function(r2.packageWrapper(PACKAGE, "global.r3 = require"))()

    assert r2
    assert r3

    delete r
    delete r2
    delete r3

  it "should be able to execute code in the package context", ->
    code = latestRequire.packageWrapper(PACKAGE, "window.test = require.packageWrapper(PACKAGE, 'alert(\"heyy\")');")
    Function(code)()
    assert window.test
    delete window.test

describe "public API", ->
  # TODO?
  # mocha.setup
  #   globals: ['system', 'OBSERVABLE_ROOT_HACK']

  it "should be able to require a JSON package directly", ->
    assert require(requireSrc).loadPackage
      distribution:
        main:
          content: "global.test2 = true"

    assert window.test2
    delete window.test2

describe "module context", ->
  # TODO
  it.skip "should know __dirname", ->
    assert.equal "lib/test/pkg", __dirname

  it "should know __filename", ->
    assert __filename

  it "should know its package", ->
    assert PACKAGE

describe "malformed package", ->
  malformedPackage =
    distribution:
      yolo: "No content!"

  it "should throw an error when attempting to require a malformed file in a package distribution", ->
    r = require(requireSrc).generateFor(malformedPackage)

    assert.throws ->
      r.require "yolo"
    , (err) ->
      !/malformed/i.test err

# TODO
describe.skip "dependent packages", ->
  it "should allow for arbitrary characters", ->
    r = require(requireSrc).generateFor
      dependencies:
        "#$!jadelet":
          entryPoint: "main"
          distribution:
            main:
              content: "module.exports = 'ok';"

    assert.equal r("#$!jadelet"), "ok"

  testPkg =
    dependencies:
      "test-pkg":
        distribution:
          main:
            content: "module.exports = PACKAGE.name"
      "strange/name":
        distribution:
          main:
            content: ""

  latestRequire = require(requireSrc).generateFor(testPkg)

  it "should raise an error when requiring a package that doesn't exist", ->
    assert.throws ->
      latestRequire "nonexistent"
    , (err) ->
      /nonexistent/i.test err

  it "should be able to require a package that exists", ->
    assert latestRequire("test-package")

  it "Dependent packages should know their names when required", ->
    assert.equal latestRequire("test-package"), "test-package"

  it "should be able to require by pretty much any name", ->
    assert latestRequire("strange/name")
