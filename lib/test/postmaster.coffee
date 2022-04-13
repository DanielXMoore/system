# NOTE: It is important to call dispose at the end of each test because
# Postmaster attaches a global event listener and needs to clean up.
Postmaster = require "../postmaster"

randId = ->
  Math.random().toString(36).substr(2)

scriptContent = ->
  # This function is toString'd to be inserted into the sub-frames.
  fn = ->
    pm = Postmaster
      delegate:
        echo: (value) ->
          return value
        throws: ->
          throw new Error("This always throws")
        promiseFail: ->
          Promise.reject new Error "This is a failed promise"
        send: ->
          pm.send(arguments...)

  """
    (function() {
    var module = {};
    (function() {
    #{PACKAGE.distribution["lib/postmaster"].content};
    })();
    var Postmaster = module.exports;
    (#{fn.toString()})();
    })();
  """

htmlContent = -> """
<html>
  <body>
    <script>#{scriptContent()}<\/script>
  </body>
</html>
"""

srcUrl = ->
  URL.createObjectURL new Blob [htmlContent()],
    type: "text/html; charset=utf-8"

dataUrl = -> "data:text/html;base64,#{btoa(htmlContent())}"

testFrame = (fn) ->
  iframe = document.createElement('iframe')
  iframe.name = "iframe-#{randId()}"
  iframe.src = srcUrl()
  document.body.appendChild(iframe)

  postmaster = Postmaster
    remoteTarget: ->
      iframe.contentWindow

  iframe.addEventListener "load", ->
    fn(postmaster)
    .finally ->
      iframe.remove()
      postmaster.dispose()

  return

describe "Postmaster", ->
  # Can't open child windows from within sandboxed iframes?
  it.skip "should work with openened windows", (done) ->
    childWindow = window.open(srcUrl(), "child-#{randId()}", "width=200,height=200")

    postmaster = Postmaster
      remoteTarget: -> childWindow

    childWindow.addEventListener "load", ->
      postmaster.send "echo", 5
      .then (result) ->
        assert.equal result, 5
      .then ->
        done()
      , (error) ->
        done(error)
      .then ->
        childWindow.close()
        postmaster.dispose()

    return

  it "should work with iframes", (done) ->
    testFrame (postmaster) ->
      postmaster.send "echo", 17
      .then (result) ->
        assert.equal result, 17
      .then done, done

    return

  it "should handle the remote call throwing errors", (done) ->
    testFrame (postmaster) ->
      postmaster.send "throws"
      .then ->
        done new Error "Expected an error"
      , (error) ->
        done()

    return

  it "should throwing a useful error when the remote doesn't define the function", (done) ->
    testFrame (postmaster) ->
      postmaster.send "undefinedFn"
      .then ->
        done new Error "Expected an error"
      , (error) ->
        done()

    return

  it "should handle the remote call returning failed promises", (done) ->
    testFrame (postmaster) ->
      postmaster.send "promiseFail"
      .then ->
        done new Error "Expected an error"
      , (error) ->
        done()

    return

  it "should be able to go around the world", (done) ->
    testFrame (postmaster) ->
      postmaster.yolo = (txt) ->
        "heyy #{txt}"
      postmaster.send "send", "yolo", "cool"
      .then (result) ->
        assert.equal result, "heyy cool"
      .then ->
        done()
      , (error) ->
        done(error)

    return

  it.skip "should work with web workers", (done) ->
    blob = new Blob [scriptContent()], type: "application/javascript"
    jsUrl = URL.createObjectURL(blob)

    worker = new Worker(jsUrl)

    postmaster = Postmaster
      remoteTarget: -> worker
      receiver: -> worker

    setTimeout ->
      postmaster.send "echo", 17
      .then (result) ->
        assert.equal result, 17
      .then ->
        done()
      , (error) ->
        done(error)
      .finally ->
        worker.terminate()
    , 100

    return

  it "should fail quickly when contacting a window that doesn't support Postmaster", (done) ->
    iframe = document.createElement('iframe')
    document.body.appendChild(iframe)

    childWindow = iframe.contentWindow
    postmaster = Postmaster
      remoteTarget: -> childWindow
      ackTimeout: -> 30

    postmaster.send "echo", 5
    .catch (e) ->
      if e.message.match /no ack/i
        done()
      else
        done(1)
    .finally ->
      iframe.remove()
      postmaster.dispose()

    return

  it "should return a rejected promise when unable to send to the target", (done) ->
    postmaster = Postmaster
      remoteTarget: -> null

    postmaster.send "yo"
    .then ->
      done throw new Error "Expected an error"
    , (e) ->
      assert.equal e.message, "No remote target"
      done()
    .catch done
    .finally ->
      postmaster.dispose()

    return

  it "should log", ->
    called = false

    postmaster = Postmaster
      logger:
        info: ->
          called = true

    assert called
    postmaster.dispose()
