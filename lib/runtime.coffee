# runtime is what prepares the environment for user apps
# we hook up the postmaster and proxy messages to the OS

{version} = require "../pixie"

Postmaster = require "./postmaster"
{applyStyle, Observable, Style} = require "../lib/ui/index"

Runtime = (system, opts={}) ->
  if opts.applyStyle
    applyStyle(Style.all, 'system')

  opts.logger ?=
    info: ->
    debug: ->

  externalObservables = {}

  # Queue up messages until a delegate is assigned
  heldApplicationMessages = []

  postmaster = Postmaster
    logger: opts.logger
    # For receiving messages from the system
    delegate:
      application: (method, args...) ->
        if applicationTarget.delegate
          applicationTarget.delegate[method](args...)
        else
          # This promise should keep the channel unresolved until the future
          new Promise (resolve, reject) ->
            heldApplicationMessages.push (delegate) ->
              try
                resolve delegate[method](args...)
              catch e
                reject e
  
      updateSignal: (name, newValue) ->
        externalObservables[name](newValue)
  
      fn: (handlerId, args) ->
        # TODO: `this` is null but should be `system` here for bound events.
        eventListeners[handlerId].apply(null, args)

  remoteExists = postmaster.remoteTarget()

  applicationTarget =
    observeSignal: (name, handler) ->
      observable = Observable()
      externalObservables[name] = observable

      observable.observe handler

      # Invoke the handler with the initial value
      postmaster.send "application", "observeSignal", name
      .then handler

  # For sending messages to ZineOS application side
  applicationProxy = new Proxy applicationTarget,
    get: (target, property, receiver) ->
      target[property] or
      ->
        return unless remoteExists
        postmaster.send "application", property, arguments...
    set: (target, property, value, receiver) ->
      if property is "delegate"
        heldApplicationMessages.forEach (fn)->
          fn(value)

        heldApplicationMessages = []

      target[property] = value

      return target[property]

  lastEventListenerId = 0
  eventListeners = {}
  readyPromise = null
  hostTarget =
    ready: ->
      return readyPromise if readyPromise

      if remoteExists
        readyPromise = postmaster.send "ready",
          ZineOSClient: version
          token: postmaster.token
        .then (hostConfig) ->
          appData = hostConfig?.ZineOS

          if appData
            initializeOnZineOS(appData)

          return hostConfig
      else 
        # Quick resolve when there is no parent window to connect to
        polyfillForStandalone()

        readyPromise = Promise.resolve
          standalone: true

    # Bind listeners to system events, sending an id in place of a local function
    # reference
    on: (eventName, handler) ->
      lastEventListenerId += 1

      eventListeners[lastEventListenerId] = handler
      postmaster.send "system", "on", eventName, lastEventListenerId

    off: (eventName, handler) ->
      [handlerId] = Object.keys(eventListeners).filter (id) ->
        eventListeners[id] is handler

      delete eventListeners[handlerId]
      postmaster.send "system", "off", eventName, handlerId

  hostTarget.target = hostTarget

  # Unattached, standalone page. Use a systemTarget for that environment
  # Currently mapping system.readFile to fetch
  polyfillForStandalone = ->
    Object.assign hostTarget,
      readFile: (path) ->
        fetch(path)
        .then (response) ->
          if 200 <= response.status < 300
            response.blob()
          else
            throw new Error(response.statusText)
      writeFile: (path, blob) ->
        blob.download(path)

  # Proxy to the host environment
  # Host methods can be overridden by writing to the host target
  # this allows us to polyfill for standalone environments (with no host)
  # and provides bindings for event channels and others things (experimental).
  host = new Proxy hostTarget,
    get: (target, property, receiver) ->
      if Object::hasOwnProperty.call(target, property)
        target[property]
      else
        ->
          postmaster.send "system", property, arguments...

  # TODO: Also interesting would be to proxy observable arguments where we
  # create the receiver on the opposite end of the membrane and pass messages
  # back and forth like magic

  initializeOnZineOS = ({id}) ->
    applicationTarget.id = id

    document.addEventListener "mousedown", ->
      applicationProxy.raiseToTop()
      .catch console.warn

  BaseApp = require("./app/index")(host, applicationProxy)

  client =
    # `postmaster` makes sense here since it is the client's postmaster instance
    postmaster: postmaster

  Object.assign system,
    # Launch stuff
    app:
      Base: BaseApp
    client: client
    config: {} # Host config gets merged into here
    host: host

    # Backwards compatible host proxy methods
    # TODO: deprecate?
    readFile: ->
      host.readFile arguments...
    readTree: ->
      host.readTree arguments...
    writeFile: ->
      host.writeFile arguments...

  # Only return {system, application}
  # Client utilities can be found in system.client
  # TODO: Remove global `application`
  application: applicationProxy
  system: system

module.exports = Runtime
