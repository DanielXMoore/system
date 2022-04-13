App
===

The system runtime provides an app base with many useful methods:

- `confirmUnsaved`
- `currentPath` Observable string
- `drop` handler that receives an array of Files on a drop event.
- `exit`
- `extend`
- `hotkey`
- `new`
- `open`
- `save`
- `saved` Observable bool representing the state of the app, saved or not.
- `saveAs`
- `paste` handler that receives an array of Files on a paste event.

Your app must provide these to make use of the paste/drop/fileIO interfaces.

- `loadFile`
- `newFile`
- `saveData`

One can optionally provide a `menu` property:

```
menu: """
  File
    New
    Open
    Save
    Save As
    ---
    Exit
  Edit
    Undo
    Redo
    Resize -> doResize
  Example
    Item One
    Item Two
    Submenu
      Sub Item One
      Sub Item Two
"""
```

This menu micro-format defines a menubar for your app. The menu items have the
name given delegating to the method of the same name except non-alphanumeric
characters are removed and the initial character is downcased, i.e. `Save As` ->
`saveAs`.

Other app methods that you can optionally define:

- `title`

Title will be observed and piped to the "host application" if it is a function with
observable dependencies.

The main idea is to combine all the common behaviors into one comprehensive
focal point.

Glossary
--------

### Observables

Observable properties are functions that store a value when called
with one argument and return that value when called with zero arguments. They
have an `observe` method.

Observable functions will automatically re-execute if they depend on observable
properties. They may be composed of any number of observable properties or
functions.

### Host

Communication channel to the host environment.

```
host.writeFile(path, blob)
```

The host environment is ZineOS or none if standalone. There may be other possible
host environments, it could be the host OS if running in Electron.

### Host Application

The ZineOS application object running inside the ZineOS frame. This holds info
about saved status, the title, a handle to the iframe or app element, and the
actual window element in ZineOS.

In standalone the host application is a thin wrapper over the browser chrome.

In summary the host application is the host environment's representation of this
application.
