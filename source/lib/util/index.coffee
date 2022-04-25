###*
Load scripts sequentially, prevents failures if there is a dependency
order
@param urls {string[]}
###
loadScripts = (urls) ->
  urls.reduce (p, url) ->
    p.then ->
      # Resolve if present
      if document.querySelector "script[src=#{JSON.stringify(url)}]"
        return Promise.resolve()

      script = document.createElement "script"
      script.src = url
      document.body.appendChild script

      return new Promise (resolve, reject) ->
        #@ts-ignore
        script.onload = resolve
        script.onerror = reject
  , Promise.resolve()

#
###*
Copy a string to user's OS (win,mac,linux) clipboard.
@param str {string}
###
copyToClipboard = (str) ->
  navigator.clipboard.writeText(str)

#
###*
@param buffer {ArrayLike<number> | ArrayBufferLike}
###
bufferToBase64 = (buffer) ->
  #@ts-ignore Argument of type 'Uint8Array' is not assignable to parameter of type 'number[]'
  window.btoa String.fromCharCode.apply null, new Uint8Array buffer

#
###*
@param base64String {string}
###
base64URLEncode = (base64String) ->
  base64String.replace(/\+/g, "-").replace(/\//g, "_").replace(/\=/g, "")

#
###*
@param data {BufferSource}
###
digest = (data) ->
  crypto.subtle.digest("SHA-256", data)

#
###*
@param string {string}
###
escapeRegex = (string) ->
  string.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&')

#
###*
Match is an array of regex match results
unmatched runs of characters followed by single character matches, alternating
["", "a", " cool ", "d", "og"]
returns a score, higher is better
@param match {RegExpMatchArray}
@return {number}
###
scoreMatch = (match) ->
  # -1 so that if first char is matched it gets consecutive bonus
  lastMatch = -1
  pos = 0
  match.slice(1).reduce (score, s, i) ->
    if s.length is 0
      value = 0
    else
      # Unmatched run
      if i % 2 is 0
        value = -s.length
      else # Matched char
        # Consecutive
        if pos is 1 + lastMatch
          lastMatch = pos
          value = 8
        else
          value =  2

    # console.log "Score: #{score}, s: '#{s}', v: #{value}"
    pos += s.length
    return score + value
  , 0

module.exports =
  copyToClipboard: copyToClipboard
  ###*
  @template {Function} T
  @param msg {string}
  @param fn {T}
  @return {(...args: Parameters<T>) => ReturnType<T>}
  ###
  deprecationWarning: (msg, fn) ->
    if typeof msg is "function"
      fn = msg
      msg = "DEPRECATED"

    ->
      console.warn msg
      #@ts-ignore
      fn.apply(this, arguments)

  escapeRegex: escapeRegex

  ###*
  @template T
  @param term {string}
  @param items {T[]}
  @param asString {(item: T) => string}
  ###
  fuzzyMatch: (term, items, asString=String) ->
    re = RegExp("^" +term.split("").map (c) ->
      "([^#{escapeRegex c}]*)(#{escapeRegex c})"
    .join('') + '(.*)$', "i")

    items.map (item) ->
      if match = asString(item).match re
        return [item, scoreMatch match]
      return undefined
    .filter (result) -> result?
    .sort (a, b) ->
      #@ts-ignore
      b[1] - a[1]
    .map (result) ->
      #@ts-ignore
      result[0]

  ###*
  @template T
  @param array {T[]}
  @param fn {(item: T) => string}
  @return {{[key: string]: T[]}}
  ###
  groupBy: (array, fn) ->
    array.reduce (result, item) ->
      #@ts-ignore
      (result[fn(item)] ?= []).push item

      return result
    , {}

  loadScripts: loadScripts

  ###*
  Takes an array of urls, returns a decorator that checks the deps have resolved
  before invoking the given function

  @param urls {string[]}
  @return {<T extends function>(fn: T) => (...args: Parameters<T>) => Promise<Awaited<ReturnType<T>>>}
  ###
  lazyLoader: (urls) ->
    # Load the dependencies keeping a promise to limit to only one request
    # clearing the limit on failure
    # caching on success
    ###* @type {Promise<any> | null} ###
    loadingDeps = null
    _load = ->
      if loadingDeps
        return loadingDeps

      loadingDeps = loadScripts(urls).catch (e) ->
        console.error e
        loadingDeps = null
        throw e

    # Decorator to ensure initialized
    return (fn) ->
      (args...) ->
        #@ts-ignore
        context = this
        _load().then ->
          fn.apply context, args

  Postmaster: require "../postmaster"

  ###*
  Limit promise requests with the same key to only one in flight

  @template {{finally: (f: () => void) => R}} R
  @param fn {(this: void, key: string) => R}
  @return {(key: string) => R}
  ###
  promiseChoke: (fn) ->
    ###* @type {{[key: string]: R} }###
    cache = {}

    (key) ->
      cached = cache[key]
      if cached
        return cached

      cache[key] = fn(key).finally ->
        delete cache[key]

  ###*
  @template T
  @template {any[]} A
  @template R
  @param wait {number}
  @param func {(this: T, ...args: A) => R}
  @return {(this: T, ...args: A) => R}
  ###
  throttle: (wait, func) ->
    #
    ###* @type {T} ###
    #@ts-ignore
    context = null
    #
    ###* @type {A} ###
    #@ts-ignore
    args = null
    #
    ###* @type {R} ###
    #@ts-ignore
    result = null

    #
    ###* @type NodeJS.Timeout | null###
    timeout = null
    previous = 0

    later = ->
      previous = Date.now()
      timeout = null
      result = func.apply(context, args)
      if !timeout
        #@ts-ignore
        context = args = null
      return

    return (_args...) ->
      now = Date.now()
      remaining = wait - (now - previous)
      context = this
      args = _args

      if remaining <= 0 || remaining > wait
        if timeout
          clearTimeout(timeout)
          timeout = null

        previous = now
        result = func.apply(context, args)
        if (!timeout)
          #@ts-ignore
          context = args = null
      else if !timeout
        timeout = setTimeout(later, remaining)

      return result

  ###*
  @param blob {Blob}
  ###
  urlSafeSHA256: (blob) ->
    blob.arrayBuffer()
    .then digest
    .then bufferToBase64
    .then base64URLEncode
