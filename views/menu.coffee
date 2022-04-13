Observable = require "../lib/observable"

assert = require "../lib/assert"

{advance, accelerateItem, asElement, get, F, S, htmlEscape, handle, isDescendant} = require "../util"

MenuTemplate = require "../templates/menu"
MenuItemTemplate = require "../templates/menu-item"

SeparatorView = require "./menu-separator"
MenuItemView = require "./menu-item"

parseMenu = require "../lib/indent-parse"

# MenuView
#
# items is an array of item data
# An item datum is either a string
# or a pair of [label:string, items...]
#
# ex. [
#   "Cool"
#   ["Submenu", [
#     "Yo",
#     "Wat"
#   ]]
# ]
#
module.exports = MenuView = ({items, classes, style, contextRoot, parent}) ->
  self = {}
  contextRoot ?=
    activeItem: Observable()
    handlers: {}

  classes ?= -> ["options"]

  {activeItem} = contextRoot
  
  if typeof items is "string"
    items = parseMenu(items)

  # Converts items from the data to the element jazz
  getItems = Observable ->
    items.map (item) ->
      switch
        when typeof item is "string" and item.match(/^[=-]+$/)
          SeparatorView()
        when Array.isArray(item)
          assert item.length is 2
          [label, submenuItems] = item
          MenuItemView
            label: label
            items: submenuItems
            MenuView: MenuView
            contextRoot: contextRoot
            parent: self
        else
          MenuItemView
            label: item
            contextRoot: contextRoot
            parent: self

  navigableItems = Observable ->
    getItems().filter (item) ->
      !item.separator

  # TODO: This gets called per menu item when the state changes
  # Could we shift it a little to only be called for the relevant subtree?
  # Possible solution: find the common ancestor of the new active and the previous
  # active and only update the necessary ones
  active = ->
    isDescendant activeItem()?.element, self.element

  Object.assign self,
    accelerate: (key) ->
      accelerateItem(getItems(), key)
    cursor: (direction) ->
      switch direction
        when "Up"
          self.advance(-1)
        when "Down"
          self.advance(1)
        else
          parent.parent?.cursor(direction)
    parent: parent
    items: getItems
    advance: (n) ->
      activeItem advance(navigableItems(), n)
    navigableItems: navigableItems
    element: MenuTemplate
      style: style
      class: ->
        [
          "active" if active()
        ].concat classes()
      click: handle (e) ->
        activeItem self
      items: ->
        getItems().map asElement

  return self
