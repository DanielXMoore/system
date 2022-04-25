{version} = require "../../pixie.cson"

Postmaster = require "./postmaster.coffee"
Runtime = require "./runtime.coffee"

module.exports = system =
  # app, client, host are merged in during the `launch` call to Runtime
  app:
    Base: -> throw new Error "app.Base can't be called until after system.launch"
  acct: require "./acct/index.coffee"
  aws: require "./aws/index.coffee"
  fs: require "./fs/index.coffee"

  ###*
  Launch the system client, attach `system` and `application` globals, send
  ready message, invoke callback.

  Once we launch system becomes a global and is extended with

  @param opts {LaunchOpts}
  @param fn {(config: SystemConfig) => void}
  ###
  launch: (opts, fn) ->
    if typeof opts is 'function'
      fn = opts
      opts = {}

    if opts.debug
      opts.logger = console

    # This is still kind of a mess
    Object.assign global, Runtime(system, opts)

    if window? and Postmaster.dominant() # We're being hosted by another window
      window.addEventListener 'unload', ->
        system.host.unload()

    system.host.ready()
    .then (hostConfig) ->
      Object.assign system.config,
        host: hostConfig
    .finally ->
      fn(system.config)

  pkg: require "./pkg/index.coffee"
  ui: require "./ui/index.coffee"
  # Merge deprecated util methods until we're ready to remove them
  util: require "./util/index.coffee"
  version: version
