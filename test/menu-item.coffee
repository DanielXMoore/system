# PACKAGE.name = "test"
require "../source/main"

MenuItemView = require "../source/views/menu-item"
Observable = require "../source/lib/observable"

describe "MenuItem", ->
  # TODO: Make context root optional

  it "should have correct custom action names", ->
    called = false

    menuItem = MenuItemView
      label: "Cool -> Super Cool"
      contextRoot:
        activeItem: ->
        handlers:
          "Super Cool": ->
            called = true

    assert !called
    menuItem.click()
    assert called
