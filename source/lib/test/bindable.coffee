test = it
ok = assert
equal = assert.equal

Bindable = require "../bindable"

describe "Bindable", ->

  test "#on and #trigger", ->
    o = Bindable()

    o.on("test", -> ok true)

    o.trigger("test")

  test "Multiple bindings", ->
    o = Bindable()

    o.on("test", -> ok true)
    o.on("test", -> ok true)

    o.trigger("test")

  test "#trigger arguments", ->
    o = Bindable()

    param1 = "the message"
    param2 = 3

    o.on "test", (p1, p2) ->
      equal(p1, param1)
      equal(p2, param2)

    o.trigger "test", param1, param2

  test "#off", ->
    o = Bindable()

    callback = ->
      ok false

    o.on "test", callback
    # Unbind specific event
    o.off "test", callback
    o.trigger "test"

    o.on "test", callback
    # Unbind all events
    o.off "test"
    o.trigger "test"

  test "* events", ->
    o = Bindable()

    called = 0
    o.on "*", (event, rest...) ->
      called += 1

      if called is 1
        assert.equal event, "edit"
        assert.equal rest[0], "cool"
        assert.equal rest[1], 5

    o.trigger "edit", "cool", 5

    assert.equal called, 1
