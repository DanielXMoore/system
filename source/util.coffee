# TODO: This is mostly internal utils / helpers
# a lot is experimenting with APIs and ergonomics
# These are not the public utils that we plan to export.

Observable = require "./lib/observable"

A = (attr) ->
  (x) -> x[attr]

F = (methodName) ->
  (x) -> x[methodName]()

get = (x, context) ->
  if typeof x is 'function'
    x.call(context)
  else
    x

# Observable attribute helper
o = (object, name) ->
  attribute = Observable(object[name])

  attribute.observe (newValue) ->
    object[name] = newValue

  return attribute

# Handle events by preventing the default action
handle = (fn) ->
  (e) ->
    return if e?.defaultPrevented
    e?.preventDefault()
    fn.call(this, e)

# I hope I don't hate myself for this later
# S for Safe invoke, invoke the method of the object, if it exists and is a
# function, otherwise return the provided default value
S = (object, method, defaultValue) ->
  ->
    if typeof object?[method] is 'function'
      object[method]()
    else
      defaultValue

asElement = A('element')

accelerateItem = (items, key) ->
  [acceleratedItem] = items.filter (item) ->
    item.accelerator is key

  if acceleratedItem
    # TODO: should there be some kind of exec rather than click action?
    acceleratedItem.click()

isDescendant = (element, ancestor) ->
  return unless element

  while (parent = element.parentElement)
    return true if element is ancestor
    element = parent

advance = (list, amount) ->
  [currentItem] = list.filter (item) ->
    item.active()

  activeItemIndex = list.indexOf(currentItem) + amount

  if activeItemIndex < 0
    activeItemIndex = list.length - 1
  else if activeItemIndex >= list.length
    activeItemIndex = 0

  list[activeItemIndex]

# TODO: Nested objects?
# TODO: Convert keys ending in [] to array entries?
# Just keeping it simple and crushing duplicate names
formDataToObject = (formData) ->
  Array.from(formData.entries()).reduce (object, [key, value]) ->
    object[key] = value

    object
  , {}

# Get the view associated with a dom element
# This will let us use the dom tree rather than manage a separate tree
# to dispatch events at the view level
# the assumption is that a .view property is written to the root element in the
# view when rendering a view's template element
elementView = (element) ->
  return unless element
  return element.view if element.view
  elementView element.parentElement

# Remove all children from a dom node
empty = (node) ->
  while node.hasChildNodes()
    node.removeChild(node.lastChild)

  return node

module.exports = Util =
  htmlEscape: (string) ->
    String(string).replace /[&<>"'\/]/g, (s) ->
      entityMap[s]

  A: A
  F: F
  S: S
  o: o

  advance: advance
  asElement: asElement
  accelerateItem: accelerateItem

  elementView: elementView
  empty: empty
  formDataToObject: formDataToObject
  get: get
  handle: handle
  isDescendant: isDescendant


entityMap =
  "&": "&amp;"
  "<": "&lt;"
  ">": "&gt;"
  '"': '&quot;'
  "'": '&#39;'
  "/": '&#x2F;'
