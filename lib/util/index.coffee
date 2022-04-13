# Load scripts sequentially, prevents failures if there is a dependency
# order
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
        script.onload = resolve
        script.onerror = reject
  , Promise.resolve()


###
Copy a string to user's OS (win,mac,linux) clipboard.
###
copyToClipboard = (str) ->
  el = document.createElement 'textarea'
  el.value = str
  el.setAttribute 'readonly', ''
  el.style.position = 'absolute'                 
  el.style.left = '-9999px'
  document.body.appendChild el

  el.select()
  document.execCommand('copy')

  document.body.removeChild(el)

bufferToBase64 = (buffer) ->
  window.btoa String.fromCharCode.apply null, new Uint8Array buffer

base64URLEncode = (base64String) ->
  base64String.replace(/\+/g, "-").replace(/\//g, "_").replace(/\=/g, "")

digest = (data) ->
  crypto.subtle.digest("SHA-256", data)

escapeRegex = (string) ->
  string.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&')

# Match is an array of regex match results
# unmatched runs of characters followed by single character matches, alternating
# ["", "a", " cool ", "d", "og"]
# returns a score, higher is better
scoreMatch = (match) ->
  return unless match

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
  deprecationWarning: (msg, fn) ->
    if typeof msg is "function"
      fn = msg
      msg = "DEPRECATED"

    ->
      console.warn msg
      fn.apply(this, arguments)

  escapeRegex: escapeRegex

  fuzzyMatch: (term, items, asString=String) ->
    re = RegExp("^" +term.split("").map (c) ->
      "([^#{escapeRegex c}]*)(#{escapeRegex c})"
    .join('') + '(.*)$', "i")

    items.map (item) ->
      if match = asString(item).match re
        [item, scoreMatch match]
    .filter (result) -> result?
    .sort (a, b) ->
      b[1] - a[1]
    .map (result) ->
      result[0]

  groupBy: (array, fn) ->
    array.reduce (result, item) ->
      (result[fn(item)] ?= []).push item

      return result
    , {}

  loadScripts: loadScripts

  # Takes an array of urls, returns a decorator that checks the deps have resolved
  # before invoking the given function
  lazyLoader: (urls) ->
    # Load the dependencies keeping a promise to limit to only one request
    # clearing the limit on failure
    # caching on success
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
        context = this
        _load().then ->
          fn.apply context, args

  Postmaster: require "../postmaster"

  # Limit promise requests with the same key to only one in flight
  promiseChoke: (fn) ->
    cache = {}
  
    (key) ->
      cached = cache[key]
      if cached
        return cached
  
      cache[key] = fn(key).finally ->
        delete cache[key]

  throttle: (wait, func) ->
    context = args = result = undefined
    timeout = null
    previous = 0

    later = ->
      previous = Date.now()
      timeout = null
      result = func.apply(context, args)
      if !timeout
        context = args = null

    return ->
      now = Date.now()
      remaining = wait - (now - previous)
      context = this
      args = arguments
      if remaining <= 0 || remaining > wait
        if timeout
          clearTimeout(timeout)
          timeout = null

        previous = now
        result = func.apply(context, args)
        if (!timeout)
          context = args = null
      else if !timeout
        timeout = setTimeout(later, remaining)

      return result

  urlSafeSHA256: (blob) ->
    blob.arrayBuffer()
    .then digest
    .then bufferToBase64
    .then base64URLEncode
