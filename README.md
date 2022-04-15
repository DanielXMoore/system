[![Coverage Status](https://coveralls.io/repos/github/DanielXMoore/system/badge.svg?branch=main)](https://coveralls.io/github/DanielXMoore/system?branch=main)

System
======

System is the framework and API layer for creating Whimsy.Space apps.

- `app`
  - `Base`
- `aws`
- `fs`
  - `Dexie` IndexedDB
  - `Package` Explore a package as a filesystem
  - `Mount` A meta-file system where that mounts other systems as paths.
  - `S3` AWS S3
- `pkg` Utilities for loading, building, running packages.
- [ui](#ui)
  - `applyStyle(styleSource, name)` TODO: this should be automatic in most cases
  - `Bindable` TODO: Not quite the right place?
  - `ContextMenu`
  - `Jadelet`
  - `MenuBar`
  - `Modal`
  - `Observable`
  - `Progress`
  - `Window`
- `util`
  - `Postmaster`


[Architecture](https://danielx.net/wiki/architecture.html)

fs
----------

The filesystem has common operations for listing, reading, writing, and deleting
files. Both local and cloud backends are implemented. Different systems can be
mounted at paths and have events translated cleanly. That's some of the magic
that powers `My Briefcase`.

pkg
---

Build and run applications with packaging.

**Deprecated** `parseDependencyPath(string, registry)` parses a path to resolve a package
shorthand to an https url. These paths are used in declaring dependencies in
package configs like:

```coffee
dependencies:
  postmaster: "distri/postmaster:master"
```

We should just switch to using https urls. If a specific build tool wants to
handle short names or a registry then that is up to the tool.

`htmlBlob(pkg, opts)` Create a blob object containing html of the package with a
self executing wrapper. This blob can then be published as a standalone webpage
or launched inside an iframe.

ui
---

Artisanal User Interface

### Menus

- Context Menu
- Menu Bar
- Nested submenus

Simple DSL for creating menus and binding to handlers.

```
{ContextMenu} = require "ui"

contextMenu = ContextMenu()
document.body.appendChild contextMenu.element
```

### Modals

- Alert
- Confirm
- Prompt

Promise returning prompts, confirms, etc.

### Actions

Hotkeys, help text, icons, enabled/disabled states.

### Z-Indexes

Is there a sane way to do z-indexes? Right now I'm just listing them.

Modal: 1000
Context Menu: 2000

Naming Conventions
---

`system` provides many namespaces such as `system.fs`, `system.ui`, etc.
Namespaces are lower case.

Those namespaces provide constructors and methods. Methods are lower initial
camel-case:

`system.util.style(...)`

Constructors are upper initial camel-case and should _not_ be called with `new`.

`system.ui.Window(...)`

Runtime
-------

Experimenting with delegating more App plumbing to system through `app.Base`.

Currently implemented as something like this in ZineOS:

```
self.executePackageInIFrame
  distribution:
    main:
      content: """
        global.app = system.app.Base({
          pkg: PACKAGE
        });
        require("./app");
        app.trigger("boot");
      """
    app:
      content: source
  dependencies:
    "!system": PACKAGE.dependencies["!system"]
```

It makes a shim package, passing ZineOS's `!system` dependency through, then
initializing a global `app` using the runtime's `system.app.Base` to wire up all the
biz, then requires the single `app` file. Finally it triggers the `boot` event
for the app.

This kind of pattern may make its way into a `util` in `system` one day. Still
experimenting with the details.

Deprecations
---

`system.client` is a deprecated namespace from when `system` was synonymous with
`system.host` and all the other namespaces lived under `system.client`.
