require "../../setup"

Jadelet = require "../jadelet"
Observable = Jadelet.Observable
#@ts-ignore
Style = require "../../style.styl"

ContextMenuView = require "../../views/context-menu"
Modal = require "../../modal"
MenuView = require "../../views/menu"
MenuBarView = require "../../views/menu-bar"
MenuItemView = require "../../views/menu-item"
ProgressView = require "../../views/progress"
TableView = require "../../views/table"
WindowView = require "../../views/window"

#
###*
create or replace the style element with the given name
@param styleContent {string}
@param className {string}
###
applyStyle = (styleContent, className) ->
  if className
    escapedName = CSS.escape(className)
    style = document.head.querySelector("style.#{escapedName}") or document.createElement "style"
    style.className = className
  else
    style = document.createElement "style"

  style.innerHTML = styleContent
  document.head.appendChild style

module.exports = {
  AceEditor: require "../../views/ace-editor"
  applyStyle
  Bindable: require "../bindable"
  ContextMenu: ContextMenuView
  Drop: require "./drop"
  FuzzyListView: require "../../views/fuzzy-list"
  Jadelet: Jadelet
  Jadelet2:
    compile: Jadelet.exec
  Login: require "../../views/login"
  Modal
  Model: require "../core"
  Menu: MenuView
  MenuBar: MenuBarView
  MenuItem: MenuItemView
  Observable: Observable
  Progress: ProgressView
  Style:
    all: Style
  Table: TableView
  # TODO: this should be removed, parseMenu should be a behavior of the
  # menu objects
  Util: # Public utilities that we export
    parseMenu: require "../indent-parse"
  Window: WindowView
}
