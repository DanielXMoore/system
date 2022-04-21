{AceEditor} = ui = require "../ui/index"

describe "ui", ->
  it "should provide an ace editor view", ->
    {initSession, modeFor} = AceEditor
    assert initSession
    assert modeFor

    assert.equal modeFor("file.js"), "javascript"
