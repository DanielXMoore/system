TODO
====

## v0.5.2

- [ ] UI
  - [ ] Update base CSS, apply consistent resets, default fonts, headings,
forms, buttons, tables, etc.
  - [x] Try out CSS variables for theming!
  - [x] Style Ace searchbox
- [x] The object exported is `lib/runtime` with a .launch method. This is a
  little strange and due to historical accident. It would be better to export
  the entire package and include a compatible `system.launch`.
- [ ] `acct.Account` refreshCredentials should be limited to one active request
at a time.
- [x] Expand Base/Mount fs with additional QoL capabilities like
  `fs.write "path.js", "string content"`. This way the utility functionality
  will be in one place. It will also be able to mount additional systems like
  `/local/`, `/session/`, etc.
- [ ] Consolidate lib/util and runtime util exports.
- [x] Fix cached "Invalid Date" meta data when saving files in S3FS.
- [x] Jadelet SVG support
- [x] Import `require` lib
- [ ] Move caching out of S3FS and into Mount or even closer to the UI as an
option.

Organization
------------

Organize the system libraries, how they are exposed and grouped. Think about
the system proxy and sending messages to the host system. Think about the
nested layers of launching apps and hooking up system handlers.

Considerations:

- Make it easy to launch an app and bind its filesystem to a subfolder of the
host system.

Bugs
----

- [x] My Briefcase can't load files in the root level, messes up the path.

Chores
------

- [ ] Don't require `pkg` to be attached to `app` maybe pass it in as an extra
  config to `BaseApp`

v1
---

Going to require a bit of exploration and improvements to core tools first.

- [ ] Lazy Loaders
  - [x] AWS
  - [ ] Compilers
    - [ ] CoffeeScript
    - [ ] Stylus
- [ ] UI playground Docs and Examples
  - [ ] Context Menu
  - [ ] Window
  - [ ] Modal
- [ ] Explore and have fun!
- [ ] Rewrite views with new knowledge of improving performance
- [ ] Simplify where possible
- [ ] Publish / Share components
  - [ ] Maybe use new plugin tech?!?!1/
- [ ] Customizable styles
- [x] Restyle with new danielx.net aesthetics
  - [x] No border radius
  - [x] Box Shadow
- [x] Figure out relationship to system-client, Jadelet, Observable, and other
dependencies. See [Architecture](https://danielx.net/wiki/architecture.html)!
  - [x] Remove bindable dep and have it in lib
  - [x] Merge system-client into here and have this become system-client.
    - [x] Lib
      - [x] drop
      - [x] extensions
      - [x] file-io
      - [x] system-client
    - ~Postmaster dep~
      - Can't run tests easily inside iframes, crashes chrome...
      - This will be maintained from danielx.net/editor/ for now
  - [x] Fix template testing in Prometheus
    - [x] Template testing depends on `system.client.Jadelet2`, if a project
    doesn't include the `!system` dependency then it won't have that for the
    preview.
- [x] Update to Jadelet2

Whimsy.space system library should have a full featured UI and utility
functions. This will give you everything you need to construct apps. It will
also provide a consistent API and sytle.

It should cover creating apps in iframes, `My Briefcase` integration, common
utility libs. Common extensions. This environment should be comfortable. It
should be relatively portable, but don't break your ass favoring portability
over ergonomics. The proper weighting is that portability is just ergonomics
over a different timeline.

Error Reporting?
------

```
// Move error event handlers into runtime as well
// Handle non-error objects
// Can only send serializable things across
window.addEventListener('error', function(e) {
  // system.error("heyy");
});
window.addEventListener('unhandledrejection', function (e) {
  // system.error({
  //   message: e.reason.message,
  //   stack: e.reason.stack
  // });
});
```

v0
---

    Modals
    ---
    ✔️Alert
    ✔️Prompt
    ✔Confirm
    ✔General

    Menus
    ---
    ✔️Menu Bar
    ✔️Context Menu
    ✔️Keyboard Navigation (Up, Down, Left, Right)
    ✔️Accelerator Keys
    ✔️Display Hotkeys
    ✔️Indicate Enabled/Disabled
    ✔️Nested Submenus

    Toaster/Popup Notifications
    ---
    Animations
    Native notifications?

    Global Hotkeys

    Loader / Progress

    Documentation
    ---
    Modals
    Menus
    Context Menus
    Hotkeys
    Windows

    Examples
    ---
    ✔Modal Progress Bar

    Windows
    ---
    ✔Draggable
    ✔Resizable (Need to add invisible overlay when moving the mouse so iframes don't jank up the resize)
    ✔Close
    ✔Maximize
    ✔Z-Index
    Option Menu

TOMAYBE
=======

Tile Windows

Forms

Tables/Grids

Lists

File Trees
