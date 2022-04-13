# TODO
# mocha.globals(['OBSERVABLE_ROOT_HACK', "application"])

systemG = require "../exports"
SystemClient = require "../runtime"

nullLogger =
  info: ->
  debug: ->

describe "Runtime", ->
  it "should return system and application proxies", ->
    {system, application} = SystemClient(systemG)

    assert system
    assert application

    # Actual API
    app = system.app.Base()
    assert.equal app.currentPath(), ""
    assert.equal app.saved(), true

    # Cleanup
    system.client.postmaster.dispose()

  it "should queue up messages until a delegate is assigned", ->
    new Promise (resolve, reject) ->
      {system, application} = SystemClient(systemG)

      {postmaster} = system.client

      postmaster.delegate.application "test1", "yo"
      .then (c) ->
        assert.equal c, "wat"

      postmaster.delegate.application "test2", "yo2"
      .then (d) ->
        assert.equal d, "heyy"
        resolve()

      application.delegate =
        test1: (a) ->
          assert.equal a, "yo"

          return "wat"

        test2: (b) ->
          assert.equal b, "yo2"
          return "heyy"

      # Cleanup
      system.client.postmaster.dispose()

  it "should connect when ready is called", (done) ->
    {system, application} = SystemClient(systemG, {
      # logger: console
    })

    system.host.ready()
    .then ->
      done()
      system.client.postmaster.dispose()

    return

  # This was madness to test, the earlier clients had their own postmasters
  # listening!! Make sure to dispose shared resources!
  it "should launch with config", ->
    systemG.launch {
      # logger: console
    } , (config) ->
      # Cleanup
      system.client.postmaster.dispose()
