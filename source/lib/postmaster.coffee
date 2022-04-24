defaultReceiver = self
ackTimeout = 1000
pmId = 0

#
###*
@typedef {import("../../types/postmaster").Constructor} Constructor
@typedef {import("../../types/postmaster").PendingResponse} PendingResponse
@typedef {import("../../types/postmaster").PostmasterEvent} PostmasterEvent
@typedef {import("../../types/postmaster").Postmaster} Postmaster
@typedef {import("../../types/postmaster").Transmission} Transmission
###

#
###*
@type {Constructor}
###
#@ts-ignore
Postmaster = (self={}) ->
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
  self.token ?= Math.random().toString()

  #
  ###* @param data {Transmission} ###
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

  #
  ###*
  @param event {PostmasterEvent}
  ###
  listener = (event) ->
    # TODO: CoffeeSense type inference
    id = 0
    method = ""
    #
    ###* @type {Postable[]} ###
    params = []
    data = event.data
    source = event.source

    target = self.remoteTarget()

    # Only listening to messages from `opener`
    # event.source becomes undefined during the `onunload` event
    # We can track a token and match to allow the final message in this case
    if source is target or (source is undefined and data.token is self.token)
      event.stopImmediatePropagation() #
      info "<-", data
      id = data.id

      switch data.type
        when "ack"
          pendingResponses[id]?.ack = true
          # TODO: warn if pending response not found?
        when "response"
          pendingResponses[id]?.resolve data.result
          # TODO: warn if pending response not found?
        when "error"
          pendingResponses[id]?.reject data.error
          # TODO: warn if pending response not found?
        when "message"
          {method, params} = data
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

  #
  ###* @type {Record<number, PendingResponse>} ###
  pendingResponses = {}
  msgId = 0

  #
  ###*
  @param id {number}
  @return {void}
  ###
  clear = (id) ->
    debug "CLEAR PENDING", id
    clearTimeout pendingResponses[id]?.timeout
    delete pendingResponses[id]
    return

  #
  ###*

  @param method {string}
  @param params {...Postable}
  @return {Promise<any>}
  ###
  self.send = (method, params...) ->
    new Promise (resolve, reject) ->
      id = ++msgId

      ackWait = self.ackTimeout()
      #
      ###* @type {number} ###
      #@ts-ignore TODO: this is the browser setTimeout, not Node's
      timeout = setTimeout ->
        unless resp.ack
          info "TIMEOUT", resp
          resp.reject new Error "No ack received within #{ackWait}"
      , ackWait

      debug "STORE PENDING", id
      #
      ###* @type {PendingResponse} ###
      resp =
        timeout: timeout
        resolve: (result) ->
          debug "RESOLVE", id, result
          resolve(result)
          clear(id)
        reject: (error) ->
          debug "REJECT", id, error
          reject(error)
          clear(id)

      pendingResponses[id] = resp

      #
      ###* @type {any} ###
      e = null

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

  self.invokeRemote = (method, params...) ->
    console.warn "Postmaster#invokeRemote is deprecated. Use #send instead."
    self.send(method, params...)

  info "INITIALIZE"

  return self

Postmaster.dominant = ->
  if window? # iframe or child window context
    opener or ((parent != window) and parent) or undefined
  else # Web Worker Context
    self

module.exports = Postmaster
