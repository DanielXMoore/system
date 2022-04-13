{advance, htmlEscape, asElement, F, S, isDescendant, accelerateItem, handle} = require "../util"

MenuItemTemplate = require "../templates/menu-item"

# MenuItemView
# An item that appears in menus
module.exports = ({label, MenuView, items, contextRoot, parent}) ->
  self = {}

  {activeItem, handlers} = contextRoot
  # TODO: This gets called per menu item when the state changes
  # Could we shift it a little to only be called for the relevant subtree?
  active = ->
    isDescendant activeItem()?.element, element

  self.active = active

  if items
    submenu = MenuView({
      items
      contextRoot
      parent: self
    })
    content = submenu.element

  # Hook in to Action objects so we can display hotkeys
  # and enabled/disabled statuses.
  [labelText, actionName] = formatAction label
  [title, accelerator] = formatLabel labelText
  action = handlers[actionName]
  disabled = S(action, "disabled", false)
  hotkey = S(action, "hotkey", "")

  click = (e) ->
    return if disabled()
    return if e?.defaultPrevented
    e?.preventDefault()

    if submenu
      activeItem submenu
      return

    action?.call?(handlers)

    # TODO: More cleanup than just clearing the active item, like also we
    # should clear accelerator state, and maybe return focus to previously
    # focused element.
    # contextRoot.finish?
    activeItem null
    contextRoot.finish?()

  element = MenuItemTemplate
    class: ->
      [
        "menu" if items
        "active" if active()
      ]
    click: click

    mousemove: (e) ->
      # Click to activate top level menus unless a menu is already active
      # then hover to show.
      return unless activeItem()

      if !e.defaultPrevented and isDescendant(e.target, element)
        # Note: We're using preventDefault to prevent handling the
        # activation above the first element that handles it
        e.preventDefault()

        activeItem self

    title: title
    content: content
    decoration: "▸" if items
    hotkey: hotkey
    disabled: disabled

  Object.assign self,
    accelerator: accelerator
    accelerate: (key) ->
      if submenu
        submenu.accelerate key
      else
        parent.accelerate key
    click: click
    parent: parent
    element: element
    submenu: submenu
    cursor: (direction) ->
      console.log "Item Cursor", direction
      if submenu and direction is "Right"
        # Select the first navigable item of the submenu
        activeItem submenu.navigableItems[0]
      else if parent.parent and direction is "Left"
        # parent is the menu,
        # parent.parent is the item in the menu containing the parent
        if parent.parent.horizontal
          parent.parent.cursor(direction)
        else
          activeItem parent.parent
      else
        parent.cursor(direction)

  return self

# Parse out custom action symbol from entries like:
#
#     [F]ont... -> showFont
#
# Falling back to formatting the action title
formatAction = (labelText) ->
  [title, action] = labelText.split("->").map F("trim")

  unless action
    action = title.replace(/[^A-Za-z0-9]/g, "")
    action = action.charAt(0).toLowerCase() + action.substring(1)

  return [title, action]

formatLabel = (labelText) ->
  accelerator = undefined
  # Parse out accelerator keys for underlining when alt is pressed
  titleHTML = htmlEscape(labelText).replace /\[([^\]]+)\]/, (match, $1) ->
    accelerator = $1.toLowerCase()
    "<span class=\"accelerator\">#{$1}</span>"

  span = document.createElement "span"
  span.innerHTML = titleHTML

  return [span, accelerator]
