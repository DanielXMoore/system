Getting Started
===

Including this as a dependency named `!system` in `pixie.cson` hooks it into the
auto-launching capabilities of ZineOS and Prometheus.

It provides `system` and `application` as global variables after taking care of
registering communication with the host if present.

`system`
---

`system` provides tools that many apps use.


### fs

`system.fs`

Filesystem components that let you read, write, list, and delete files. It
also provides a `MountFS` that lets you mount systems at specific paths.

### ui

`system.ui`

User interface components, windows, lists, trees, and more!

### util

`system.util`

`style`

`extensions`

`application`
---



Internals
----

Apps launched from Prometheus and ZineOS use the special dependency `!system` to
wrap the launcher code for the package.

```javascript
require("!system").launch(function() {
  #{code}
});
```

The `!system` dependency provides a `launch` method that takes a function of the
code to run when the system is ready. It takes care of connecting to the host,
if present, setting up Postmaster for communication, adding an unload/error
listeners, and configuring the environment for the app.

In theory there could be any number of compatible `!system` packages as long as
they wire up the communications and adhere to the `launch` interface. Currently
there is only [danielx.net/system](https://danielx.net/system/docs/README.html)
and the communication protocol is still an evolving area.

