# Handle basic file saving/loading/picking, displaying modals/ui. This maps
# common UI patterns to the `host`'s `readFile` and `writeFile` methods.

# Caller must provide `self` object with the following methods:
#   `loadFile` Take a blob and path and load it as the application state.
#   `saveData` Return a promise that will be fulfilled with a blob of the
#     current application state.
#   `newFile` Initialize the application to an empty state.

# This extends the `self` object with:
# `currentPath`
# `drop`
# `exit`
# `new`
# `open`
# `save`
# `saved`
# `saveAs`

# It is expected that there is only one FileIO per page,
# additional apps spawn in iframes or separate windows for isolation.
# We add a global drop listener here.

## Events
#
# `boot`
# `dispose`
#
# Thought: Would it be better to call these `start` and `finish`?

{applyStyle, Drop, Jadelet, MenuBar, Modal, Observable, Style} = require "../ui/index"

# TODO: This is expanding a bit beyond FileIO and into general IO of the
# app in its environment. We should pass the application proxy in here too and
# wire it up. The application proxy should also handle the interface to
# standalone mode things like window.title onbeforeunload behavior, etc.

# Some more thoughts on `application` here... it's not really the right place
# it needs to be bound to the app after boot when it can listen to the app's
# observable properties and bind them to window.title, etc.

Bindable = require "../bindable"

{crudeRequire} = require "../pkg/index"

TemplateLoader = require "./template-loader"
Hotkeys = require "./hotkeys"

# host is used for readFile and writeFile
# application is used for syncing with the OS App state:
# - exit
# - icon
# - saved
# - title
#
# and setting the delegate on boot to receive messages sent from the host.

module.exports = (host, application) ->
  (app={}) ->
    app.saved ?= Observable true
    app.currentPath ?= Observable ""
    app.config ?= {}

    # Includes
    Bindable null, app
    Hotkeys app

    Object.assign app,
      confirmUnsaved: ->
        return Promise.resolve() if app.saved()
  
        new Promise (resolve, reject) ->
          Modal.confirm "You will lose unsaved progress, continue?"
          .then (result) ->
            if result
              resolve()
            else
              reject()

      exit: ->
        application.exit()

      extend: Object.assign.bind(null, app)

      # Accepts an array of dropped files
      # returns true if we handled the event
      # apps can override this to customize their behavior
      drop: (files) ->
        file = files[0]
        app.loadFile file, file.name
        return true

      # Accepts an array of pasted files
      # returns true if we handled the event
      # apps can override this to customize their behavior
      paste: (files) ->
        file = files[0]
        app.loadFile file, file.name
        return true

      new: ->
        if app.saved()
          app.currentPath ""
          app.newFile()
        else
          app.confirmUnsaved()
          .then ->
            app.saved true
            app.newFile()

      open: ->
        app.confirmUnsaved()
        .then  ->
          # TODO: File browser
          # TODO: Delegate to specific strategies
          Modal.prompt "File Path", app.currentPath()
          .then (newPath) ->
            if newPath
              app.currentPath newPath
            else
              throw new Error "No path given"
          .then (path) ->
            host.readFile path, true
            .then (file) ->
              app.loadFile file, path
        .catch (e) ->
          throw e if e

      reloadStyle: (cssText) ->
        applyStyle cssText, "app"

      save: ->
        path = app.currentPath()
        if path
          Promise.resolve()
          .then ->
            app.saveData()
          .then (blob) ->
            # TODO: Delegate to specific save strategy
            # zineOS, standalone, electron, ...
            # maybe application.writeFile?
            host.writeFile path, blob, true
          .then ->
            app.saved true
            return path
        else
          app.saveAs()

      saveAs: ->
        Modal.prompt "File Path", app.currentPath()
        .then (path) ->
          if path
            app.currentPath path
            app.save()

    # Detecting standalone config flag and provide alternative open and save
    # methods
    if system.config?.standalone
      ReaderInput = require "../../templates/reader-input"

      # Override chooser to use local PC
      app.open = ->
        Modal.show ReaderInput
          accept: app.accept?()
          select: (file) ->
            Modal.hide()
            app.loadFile file
    
      # Override save to present download
      app.save = ->
        Modal.prompt "File name", "newfile.txt"
        .then (name) ->
          app.saveData()
        .then (blob) ->
          blob.download()

    # Provide drop event
    # TODO: Remove drop handlers on dispose
    Drop document, (e) ->
      return if e.defaultPrevented

      files = e.dataTransfer.files

      if files.length
        e.preventDefault() if app.drop files

    # Provide paste event
    # TODO: Remove paste handlers on dispose
    document.addEventListener "paste", (e) ->
      return if e.defaultPrevented
      
      {clipboardData} = e
      
      files = clipboardData.files

      if files.length
        if app.paste files
          return e.preventDefault()

      files = Array::map.call e.clipboardData.items, (item) ->
        item.getAsFile()
      .filter (file) -> file

      if files.length
        e.preventDefault() if app.paste files

    try
      app.T ?= {}
      TemplateLoader app.pkg, app.T

    try
      app.version = crudeRequire(app.pkg.distribution.pixie.content).version

    # `boot` triggers
    app.on "boot", ->
      # Auto-apply base and app styles
      unless app.config.baseStyle is false
        applyStyle Style.all, "base"
      if @style
        applyStyle @style, "app"
      else
        try
          applyStyle crudeRequire(app.pkg.distribution.style.content), "app"

      # Auto-menu from menu string
      if @menu
        menuBar = MenuBar
          items: @menu
          handlers: @

        document.body.appendChild menuBar.element
        app.on "dispose", ->
          menuBar.element.remove()
          Jadelet.dispose menuBar.element

      if @element
        document.body.appendChild @element
      else if @template
        @element = Jadelet.exec(@template)(this)
        document.body.appendChild @element
      else if @T.App
        @element = @T.App this
        document.body.appendChild @element

      # Bind host application pieces
      application.delegate = @
      # auto-bind application title
      # Pipes title changes to os application window, etc.
      if @title?
        Observable -> application.title getProp app, "title"

      if @icon?
        Observable ->
          application.icon getProp app, "icon"

      # Pipe saved state to os app state
      if @saved?
        Observable -> application.saved getProp app, "saved"

      # TODO: onbeforeunload?

    app.on "dispose", ->
      if @element
        @element.remove()
        Jadelet.dispose @element

    return app

getProp = (context, prop) ->
  if typeof context[prop] is 'function'
    context[prop]()
  else
    context[prop]
