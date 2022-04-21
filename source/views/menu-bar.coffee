# The MenuBar is a list MenuItems arranged in a bar across the top of a page or
# window.

Observable = require "../lib/observable"

MenuView = require "./menu"

{isDescendant, advance} = require "../util"

module.exports = ({items, handlers}) ->
  acceleratorActive = Observable false
  # Track active menus and item for navigation
  activeItem = Observable null
  previouslyFocusedElement = null

  contextRoot =
    activeItem: activeItem
    handlers: handlers

  self = MenuView
    classes: ->
      [
        "bar"
        "accelerator-active" if acceleratorActive()
      ]
    items: items
    contextRoot: contextRoot

  element = self.element

  # Redefine cursor movement
  self.cursor = (direction) ->
    switch direction
      when "Right"
        self.advance(1)
      when "Left"
        self.advance(-1)

  # Redefine expand to down and not right on menu items
  self.items.forEach (item) ->
    item.horizontal = true
    item.cursor = (direction) ->
      console.log "Item", direction
      if direction is "Down"
        item.submenu?.advance(1)
      else if direction is "Up"
        item.submenu?.advance(-1)
      else
        item.parent.cursor direction

  deactivate = ->
    activeItem null
    acceleratorActive false
    # De-activate menu and focus previously focused element
    previouslyFocusedElement?.focus()

  document.addEventListener "mousedown", (e) ->
    unless isDescendant(e.target, element)
      acceleratorActive false
      activeItem null

  document.addEventListener "keydown", (e) ->
    {key} = e
    switch key
      when "Enter"
        activeItem()?.click()
      when "Alt"
        menuIsActive = false
        if acceleratorActive() or menuIsActive
          deactivate()
        else
          # Store previously focused element
          # Get menu ready for accelerating!
          previouslyFocusedElement = document.activeElement
          element.focus()
          activeItem self unless activeItem()
          acceleratorActive true

  # Dispatch the key to the active menu element
  accelerateIfActive = (key) ->
    if acceleratorActive()
      activeItem()?.accelerate(key)

  # We need to be able to focus the menu to receive keyboard events on it
  element.setAttribute("tabindex", "-1")
  element.addEventListener "keydown", (e) ->
    {key} = e

    switch key
      when "ArrowLeft", "ArrowUp", "ArrowRight", "ArrowDown"
        e.preventDefault()
        direction = key.replace("Arrow", "")

        currentItem = activeItem()

        if currentItem
          currentItem.cursor(direction)

      when "Escape"
        deactivate()
      else
        # Only prevent default if we successfully accelerated?
        accelerated = accelerateIfActive(key.toLowerCase())
        if accelerated?
          e.preventDefault()

  return self
