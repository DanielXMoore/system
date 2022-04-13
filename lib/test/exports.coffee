system = require "../exports"

describe "exports", ->
  it "should provide fs", ->
    # Four filesystem types and counting!
    assert system.fs
    assert system.fs.Dexie
    assert system.fs.Mount
    assert system.fs.Package
    assert system.fs.S3

    assert system.aws.Cognito

  it "should provide acct.login", ->
    assert system.acct.login

  it "should provide util", ->
    assert system.util.Postmaster

  it "should provide ui", ->
    {Bindable, Drop, Jadelet, Observable} = system.ui

    assert Bindable
    assert Drop
    assert Jadelet
    assert.equal typeof Observable, "function"
