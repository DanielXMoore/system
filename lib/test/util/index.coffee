require "../../extensions"
{
  copyToClipboard
  deprecationWarning
  fuzzyMatch
  groupBy
  lazyLoader
  promiseChoke
  throttle
  urlSafeSHA256
} = require "../../util/index"

describe "util", ->
  describe "copyToClipboard", ->
    it "should copy a string to system clipboard", ->
      copyToClipboard "yolo"

  describe "deprecationWarning", ->
    it "should display an error when calling a deprecated function", ->
      yolo = (x, y) ->
        x + y

      yolo = deprecationWarning "util.yolo is deprecated use based.swag instead", yolo

      # Mock console
      do (warn=console.warn) ->
        called = false
        console.warn = (msg) ->
          called = true
          assert.equal msg, "util.yolo is deprecated use based.swag instead"
        assert.equal yolo(5, 3), 8
        console.warn = warn
        assert called

  describe "fuzzyMatch", ->
    it "should match fuzzily", ->
      assert fuzzyMatch "", [""]
      assert fuzzyMatch "", ["a"]
      assert fuzzyMatch "a", ["a"]

      result = fuzzyMatch("acd", [
        "a gcac"
        "a cool dog"
        "achieved"
        "yoro"
        "what act duder"
      ])

      assert.equal result.length, 3


  describe "groupBy", ->
    it "should group arrays by fn", ->
      a = [1, 2, 3, 4, 5, 6, 7, 8, 9]
      result = groupBy a, (n) ->
        n % 3

      assert.deepEqual result[0], [3, 6, 9]
      assert.deepEqual result[1], [1, 4, 7]
      assert.deepEqual result[2], [2, 5, 8]

  describe "lazyLoader", ->
    it "should lazy load", ->
      LL = lazyLoader([])

      a = (x) -> x
      b = LL a

      b(0).then (x) ->
        assert.equal x, 0

  describe "promiseChoke", ->
    it "should limit promise returning function execution to one at a time", ->
      called = 0
      fn = promiseChoke ->
        called++
        new Promise (resolve) ->
          setTimeout resolve

      fn()
      fn()
      fn().then ->
        assert.equal called, 1

    it "should reset on error", ->
      called = 0
      fn = promiseChoke ->
        called++
        new Promise (resolve, reject) ->
          setTimeout reject

      fn()
      fn()
      fn().catch ->
        assert.equal called, 1
        fn().catch ->
          assert.equal called, 2

    it "should key off of first argument", ->
      called = 0
      fn = promiseChoke (x) ->
        called++
        new Promise (resolve) ->
          setTimeout ->
            resolve x

      fn(1)
      fn(2)
      fn(5).then (v) ->
        assert.equal v, 5
        assert.equal called, 3

  describe "throttle", ->
    it "should be called no more than once per time block", (done) ->

      called = 0

      f = throttle 15, -> called += 1

      f()
      f()
      f()

      setTimeout ->
        f()

      setTimeout ->
        f()
      , 5

      setTimeout ->
        f()
      , 10

      setTimeout ->
        if called != 2
          done new Error "Should have been called twice"
        else
          done()
      , 20

  describe "urlSafeSHA256", ->
    it "should create a URL safe SHA256 for the blob", ->
      urlSafeSHA256(new Blob ["yolo"])
      .then (str) ->
        assert.equal str, "MR_j_u0Wuc2N8PixUXvly4YEhwffSIm6jcN9TWiGbQI"
