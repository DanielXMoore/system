###
Bind app hotekeys. Assumes global context, not currently safe for multiple
instances. Reloading "works" by overwriting previous bindings.

Status: Active Experiment in Paint Composer, consolidating here.
###

{exec:compileTemplate} = require "../jadelet"
{groupBy} = require "../util/index"

Mousetrap = require "../mousetrap"

# Override default stop callback behavior
Mousetrap::stopCallback = (e, element, combo) ->
  # Don't stop for ctrl+key etc. even in textareas
  if combo.match /^(ctrl|alt|meta|option|command)\+/
    return false

  # stop for input, select, textarea, and content editable
  return element.tagName == 'INPUT' || element.tagName == 'SELECT' || element.tagName == 'TEXTAREA' || (element.contentEditable && element.contentEditable == 'true')


HotkeyTable = compileTemplate """
table
  thead
    tr
      th(colspan="2") Hotkeys
  tbody
    @rows
"""
HotkeyRow = compileTemplate """
tr
  td @name
  td.right
    code @key
"""
HotkeyCategoryRow = compileTemplate """
tr.hotkey-category
  th(colspan="2") @group
"""

categoryAttr = (m) -> m.category

module.exports = (self) ->
  hotkeys = []

  Object.assign self,
    hotkey: ->
      self.addHotkey(arguments...)
    addHotkey: (key, method, meta) ->
      if meta
        if typeof key is 'string'
          keyString = key
        else
          keyString = key.join ','

        hotkeys.push Object.assign {
          key: keyString
        }, meta

      # Note: Using the global Mousetrap instance
      # added hotkeys will replace others with the same key
      # no cleanup since there is no way to remove event listeners from
      # bound instances: https://github.com/ccampbell/mousetrap/pull/427
      Mousetrap.bind key, (e) ->
        return if e.defaultPrevented
        e.preventDefault()

        if typeof method is "function"
          method.call(self, e)
        else
          self[method](e)

    # Add info without binding hotkey
    # useful for large batches of similar keys like 0-9 to select a numbered tool
    addHotkeyInfo: (meta) ->
      hotkeys.push meta

    hotkeys: ->
      hotkeys

    hotkeysInfoElement: ->
      aggregatedHotkeys = groupBy hotkeys, categoryAttr

      rows = Object.keys(aggregatedHotkeys).reduce (result, group) ->
        entries = aggregatedHotkeys[group]

        result.push HotkeyCategoryRow
          group: group

        return result.concat entries.map HotkeyRow
      , []

      return HotkeyTable
        rows: rows
