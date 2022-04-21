{
  startsWith
  endsWith
} = require "../polyfill"

describe "Polyfill", ->
  describe "String", ->
    it "startsWith", ->
      assert "".startsWith

      assert.equal startsWith.call("abcd", "ab"), true
      assert.equal startsWith.call("abcd", "ab", -1), true
      assert.equal startsWith.call("abcd", "ab", 0), true
      assert.equal startsWith.call("abcd", "ab", 1), false
      assert.equal startsWith.call("abcd", "b", 1), true

    it "endsWith", ->
      assert "".endsWith

      assert.equal endsWith.call("abcd", "cd"), true
      assert.equal endsWith.call("raddad", "rad", 3), true
