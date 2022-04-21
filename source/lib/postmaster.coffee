###

Postmaster wraps the `postMessage` API with promises.

###

defaultReceiver = self
ackTimeout = 1000
pmId = 0

module.exports = Postmaster = (self={}) ->
  name = "#{defaultReceiver.name}-#{++pmId}"

  info = ->
    self.logger.info(name, arguments...)

  debug = ->
    self.logger.debug(name, arguments...)

  dominant = Postmaster.dominant()
  self.remoteTarget ?= -> dominant
  self.receiver ?= -> defaultReceiver
  self.ackTimeout ?= -> ackTimeout
  self.delegate ?= self
  self.logger ?=
    info: ->
    debug: ->
  self.targetOrigin ?= "*"
  self.token ?= Math.random()

  send = (data) ->
    target = self.remoteTarget()
    if self.token
      data.token = self.token

    data.from = name

    if !target
      throw new Error "No remote target"

    info("->", data)

    if !Worker? or target instanceof Worker
      target.postMessage data
    else
      target.postMessage data, self.targetOrigin

    return

  listener = (event) ->
    {data, source} = event
    target = self.remoteTarget()

    # Only listening to messages from `opener`
    # event.source becomes undefined during the `onunload` event
    # We can track a token and match to allow the final message in this case
    if source is target or (source is undefined and data.token is self.token)
      event.stopImmediatePropagation() # 
      info "<-", data
      {type, method, params, id} = data

      switch type
        when "ack"
          pendingResponses[id]?.ack = true
        when "response"
          pendingResponses[id].resolve data.result
        when "error"
          pendingResponses[id].reject data.error
        when "message"
          Promise.resolve()
          .then ->
            if source
              send
                type: "ack"
                id: id

            if typeof self.delegate[method] is "function"
              self.delegate[method](params...)
            else
              throw new Error "`#{method}` is not a function"
          .then (result) ->
            if source
              send
                type: "response"
                id: id
                result: result
          .catch (error) ->
            if typeof error is "string"
              message = error
            else
              message = error.message

            if source
              send
                type: "error"
                id: id
                error:
                  message: message
                  stack: error.stack
    else
      debug "DROP message", event, "source #{JSON.stringify(data.from)} does not match target"

  receiver = self.receiver()
  receiver.addEventListener "message", listener
  self.dispose = ->
    receiver.removeEventListener "message", listener
    info "DISPOSE"

  pendingResponses = {}
  msgId = 0

  clear = (id) ->
    debug "CLEAR PENDING", id
    clearTimeout pendingResponses[id].timeout
    delete pendingResponses[id]

  self.send = (method, params...) ->
    new Promise (resolve, reject) ->
      id = ++msgId

      ackWait = self.ackTimeout()
      timeout = setTimeout ->
        unless resp.ack
          info "TIMEOUT", resp
          resp.reject new Error "No ack received within #{ackWait}"
      , ackWait

      debug "STORE PENDING", id
      pendingResponses[id] = resp =
        timeout: timeout
        resolve: (result) ->
          debug "RESOLVE", id, result
          resolve(result)
          clear(id)
        reject: (error) ->
          debug "REJECT", id, error
          reject(error)
          clear(id)

      try
        send
          type: "message"
          method: method
          params: params
          id: id
      catch e
        setTimeout ->
          reject(e)
        , 0

      return

  self.invokeRemote = ->
    console.warn "Postmaster#invokeRemote is deprecated. Use #send instead."
    self.send(arguments...)

  info "INITIALIZE"

  return self

Postmaster.dominant = ->
  if window? # iframe or child window context
    opener or ((parent != window) and parent) or undefined
  else # Web Worker Context
    self
