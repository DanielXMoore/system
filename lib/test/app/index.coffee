{Observable} = require "/lib/ui/index"

AppGen = require "/lib/app/index"

appProxyMock = {}

BaseApp = AppGen({}, appProxyMock)

describe "App", ->
  it "should provide a base app constructor", ->
    assert BaseApp()

  it "should work standalone", ->
    do (oldSystem=system) ->
      global.system =
        config:
          standalone: true

      assert BaseApp()

      global.system = oldSystem

  it "should add a hotkey", ->
    app = BaseApp()

    called = 0
    app.hotkey "a", (e) ->
      called++

    e = new KeyboardEvent('keypress', {keyCode: 97})
    document.dispatchEvent e

    assert.equal called, 1

  it "should extend", ->
    app = BaseApp()

    app.extend
      cool: "duder"

    assert.equal app.cool, "duder"

  it "should include bindable", ->
    app = BaseApp()

    assert app.on
    assert app.off
    assert app.trigger

  it "should set title and icon", ->
    saved = icon = title = null

    appProxyMock.title = (_title) ->
      title = _title
    appProxyMock.icon = (_icon) ->
      icon = _icon
    appProxyMock.saved = (_saved) ->
      saved = _saved

    app = BaseApp
      title: "yolo"
      icon: "R"
      saved: false

    app.trigger 'boot'
    
    assert.equal icon, "R"
    assert.equal title, "yolo"
    assert.equal saved, false

  it "should pass on observable title changes", ->
    title = null

    appProxyMock.title = (_title) ->
      title = _title

    app = BaseApp
      title: Observable "wat"

    app.trigger 'boot'
    assert.equal title, "wat"

    app.title "cool"
    assert.equal title, "cool"

  it "should apply app template by default on boot and remove on dispose", ->
    app = BaseApp
      T:
        App: system.ui.Jadelet.exec "app Hello"
      menu: """
        Hello
          Wat
      """

    app.trigger 'boot'
    assert document.querySelector 'app'
    app.trigger 'dispose'
    assert !document.querySelector('app')
