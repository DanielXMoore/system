{
  compile
  crudeRequire
  exec
  htmlForPackage
  jsForPackage
  minify
  ModLoader
  registerCompiler
  Require
} = require "/lib/pkg/index"

mocha.setup
  globals: [
    'CoffeeScript'
    'marked'
    'stylus'
    'UglifyJS'
  ]

testPkg = 
  distribution:
    main:
      content: "alert('heyy');"
  dependencies:
    "!system": PACKAGE
  config:
    description: "Yolo"

describe "pkg", -> 
  describe "htmlForPackage", ->
    it "should blob up html", ->
      blob = htmlForPackage testPkg

      assert blob instanceof Blob

  describe "compile", ->
    it "should compile CoffeeScript by lazy loading compiler", ->
      compile("hello.coffee", "alert 'hello'")

    it "should 'compile' JavaScript", ->
      src = "alert('hello');"
      compile("hello.js", src)
      .then (program) ->
        assert.equal program, src

    it "should compile markdown after lazy loading compiler", ->
      compile "TODO.md", """
        - [x] Lazy Load compilers
      """

    it "should compile stylus after lazy loading compiler", ->
      compile "yo.styl", """
        body
          background-color: green
      """

    it "should fail if no known compiler", ->
      compile "wat.doot", ""
      .catch (e) ->
        assert.equal e.message, "Couldn't compile 'wat.doot'. No compiler for '.doot'"

    it "should register compilers", ->
      registerCompiler "doot", -> "doot"

      compile "wat.doot", ""

  describe "exec", ->
    it "should bind this", ->
      x = {}
      y = exec("return this", null, x)
  
      assert.equal x, y
  
    it "env is optional", ->
      r = exec("return 5")
  
      assert.equal r, 5

    it "should bind env values", ->
      r = exec("return a + this", {a: 2}, 3)

      assert.equal r, 5

  describe "crudeRequire", ->
    it "should return what is exported", ->
      result = crudeRequire """
        module.exports = "cool";
      """

      assert.equal result, "cool"

  describe "Require", ->
    it "should be exported", ->
      assert Require

  describe "jsForPackge", ->
    it "should generate a string of js", ->
      js = jsForPackage(PACKAGE)
      assert typeof js is 'string'

  describe.skip "minify", ->
    it "makes packages smaller", ->
      minify(PACKAGE, console)
      .then console.log

  describe "Mod Loader", ->
    it "should load remote modules", ->
      ModLoader
