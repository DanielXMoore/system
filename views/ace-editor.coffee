###
An element containing an ace editor.

Depends on ace and language tools extension being available in the environment.
###

{extensionFor} = require "../lib/fs/index"
{deprecationWarning, loadScripts} = require "../lib/util/index"

defaultSessionOptions =
  readOnly: false
  focus: true

# Commands to remove from Ace
removeCommands = """
  jumptomatching
  modeSelect
  modifyNumberDown
  modifyNumberUp
  movelinesdown
  movelinesup
""".split(/\r?\n/)

# No way to safely check local storage without try/catch
try
  defaultTheme = localStorage.getItem("ace/theme")
catch
  defaultTheme = "dracula"

module.exports = AceEditor = ->
  ace.require("ace/ext/language_tools")
  # Remove previous ace style if it exists
  document.querySelector("style#ace_searchbox")?.remove()
  ace.require("ace/lib/dom").importCssString(searchStyleCSS, "ace_searchbox")

  element = document.createElement "section"

  editor = ace.edit element
  editor.$blockScrolling = Infinity
  editor.setOptions
    fontFamily: "'Fira Code', 'Monaco', 'Menlo', 'Ubuntu Mono', 'Consolas', 'source-code-pro', monospace"
    fontSize: "16px"
    enableBasicAutocompletion: true
    enableLiveAutocompletion: true
    highlightActiveLine: true
    newLineMode: "unix"
    theme: "ace/theme/#{defaultTheme}"

  removeCommands.forEach (command) ->
    editor.commands.removeCommand command

  self =
    # deprecated aceEditor -> editor
    aceEditor: editor

    editor: editor
    element: element

    hidden: (b) ->
      if b
        element.classList.add("hidden")
      else
        element.classList.remove("hidden")

    goto: (line=0, selection) ->
      editor.moveCursorTo(line, 0)

      editor.clearSelection()

      if selection
        session = editor.getSession()
        start = session.doc.indexToPosition(selection.start)
        end = session.doc.indexToPosition(selection.end)
        editor.selection.setSelectionRange({start, end})

      editor.scrollToLine(line, true, false, ->)

      return

    setSession: (session, opts=defaultSessionOptions) ->
      {readOnly, focus} = opts

      editor.setSession(session)
      editor.setReadOnly(readOnly)
      if focus
        editor.focus()

      return

    theme: (name) ->
      editor.setTheme("ace/theme/#{name}")
      try
        localStorage.setItem "ace/theme", name

  return self

###
Initialize a session to track an observable
###
initSession = (initialContent, contentObservable, mode="coffee") ->
  return unless contentObservable
  session = ace.createEditSession(initialContent)

  # Remove janky CSSLint rules
  session.on "changeMode", ->
    if session.$mode.$id is "ace/mode/css"
      session.$worker.call 'setDisabledRules',
        ["ids|order-alphabetical|universal-selector|regex-selectors"]

  session.setUseWorker(false)

  session.setMode("ace/mode/#{mode}")
  session.setUseSoftTabs true
  session.setTabSize 2

  updating = 0
  contentObservable.observe (newContent) ->
    return if updating
    updating++
    session.setValue newContent
    updating--

  # Bind session and file content
  session.on "change", ->
    return if updating
    updating++
    contentObservable session.getValue()
    updating--

  return session

modes =
  cson: "coffee"
  jadelet: "jade"
  js: "javascript"
  md: "markdown"
  styl: "stylus"
  txt: "text"

Object.assign AceEditor,
  initAceSession: deprecationWarning "initAceSession -> initSession", initSession
  initSession: initSession

  modeFor: (path) ->
    extension = extensionFor(path)
    return modes[extension] or extension

  preload: ->
    loadScripts ["https://cdnjs.cloudflare.com/ajax/libs/ace/1.4.7/ace.js"]

searchStyleCSS = """
.ace_search {
  background-color: var(--background-neutral);
  color: var(--text-color);
  border: 1px solid var(--neutral-dark);
  border-top: 0;
  margin: 0;
  padding: 0.5em;
  position: absolute;
  top: 0;
  z-index: 99;
}
.ace_search.right {
  border-radius: 0px 0px 0px var(--border-radius);
  border-right: 0;
  right: -5px;
}
.ace_search.left {
  border-left: 0 none;
  border-radius: 0 0 var(--border-radius) 0;
  left: -5px;
}
.ace_search > * {
  margin-bottom: 0.5em;
}
.ace_search > *:last-child {
  margin-bottom: 0;
}
.ace_searchbtn_close {
  background: url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAA4AAAAcCAYAAABRVo5BAAAAZ0lEQVR42u2SUQrAMAhDvazn8OjZBilCkYVVxiis8H4CT0VrAJb4WHT3C5xU2a2IQZXJjiQIRMdkEoJ5Q2yMqpfDIo+XY4k6h+YXOyKqTIj5REaxloNAd0xiKmAtsTHqW8sR2W5f7gCu5nWFUpVjZwAAAABJRU5ErkJggg==) no-repeat 50% 0;
  border-radius: var(--border-radius);
  border: 0;
  cursor: pointer;
  padding: 0;
  height: 14px;
  width: 14px;
  top: 9px;
  right: 0.75em;
  position: absolute;
}
.ace_searchbtn_close:hover {
  background-color: #656565;
  background-position: 50% 100%;
}
.ace_search_form,
.ace_replace_form {
  display: flex;
  justify-content: start;
  margin-right: 1.75em;
}
.ace_replace_form {
  margin-right: 0;
}
.ace_search_field {
  z-index: 1;
}
.ace_search_form.ace_nomatch > .ace_search_field {
  border-color: var(--error-color);
  outline: 2px solid var(--error-color);
}
.ace_searchbtn,
.ace_button {
  background-color: var(--background-color);
  border: 1px solid var(--neutral-darker);
  border-radius: var(--border-radius);
  box-shadow: var(--shadow-low) var(--neutral-dark);
  cursor: pointer;
  display: inline-block;
  padding: 0.125em 0.375em;
}
.ace_searchbtn:hover,
.ace_button:hover {
  background-color: var(--neutral-faintest);
}
.ace_searchbtn:active,
.ace_button:active,
.ace_searchbtn.active,
.ace_button.active,
.ace_searchbtn.checked,
.ace_button.checked {
  background-color: var(--neutral-faintest);
  box-shadow: var(--shadow-low) var(--neutral-dark) inset;
}
.ace_searchbtn:last-child {
  border-radius: 0 var(--border-radius) var(--border-radius) 0;
}
.ace_searchbtn.prev,
.ace_searchbtn.next {
  display: flex;
  align-items: center;
}
.ace_searchbtn.prev:after,
.ace_searchbtn.next:after {
  content: "";
  border: solid 0 var(--text-color);
  width: 0.5em;
  height: 0.5em;
  border-width: 1px 0 0 1px;
  display: inline-block;
  transform: rotate(-45deg);
}
.ace_searchbtn.next:after {
  border-width: 0 1px 1px 0;
}
.ace_search_options {
  display: flex;
  align-items: center;
}
user-select: none {
  clear: both;
}
.ace_search_counter {
  padding: 0 0.5em;
  margin-right: auto;
}
"""
