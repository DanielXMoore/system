###
Interface to all our AWS madness.

###

{urlSafeSHA256} = require "../util/index"

LL = require "./_lazy"

module.exports =
  Cognito: require "./cognito"

  # requires that the user has been authorized with Cognito
  # TODO: catch and refresh credentials
  api: LL (path, params={}) ->
    url = new URL "https://api.whimsy.space/#{path}"
    url.searchParams.append "idpjwt", Object.values(AWS.config.credentials.params.Logins)[0]

    if params.body?
      params.body = JSON.stringify params.body

    fetch url, params

  # Requires that the user has been authorized with Cognito
  cdn: LL (blob) ->
    S3 = new AWS.S3
      params:
        Bucket: "whimsy-fs"

    S3.config.credentials = AWS.config.credentials
    id = AWS.config.credentials.identityId

    queryExisting = (sha) ->
      fetch "https://whimsy.space/cdn/#{sha}",
        method: 'HEAD'
      .then (response) ->
        response.status is 200

    # Compute urlsafe sha256
    urlSafeSHA256(blob)
    .then (sha) ->
      queryExisting(sha)
      .then (found) ->
        return sha if found

        # Post to whimsy-fs/incoming/user-id/sha
        S3.putObject
          Key: "incoming/#{id}/#{sha}"
          ContentType: blob.type
          Body: blob
        .promise()
        .then ->
          # Gently poll whimsy.space/cdn/sha
          # reslove when available
          new Promise (resolve, reject) ->
            timeout = 1000
            n = 0

            check = ->
              n += 1

              if n <= 10
                queryExisting(sha)
                .then (found) ->
                  if found
                    resolve(sha)
                  else
                    setTimeout ->
                      check()
                    , timeout
              else
                reject()

            check()

  # Open an authenticated websocket connection to the whimsy.space server
  ws: ->
    url = new URL "wss://ws.whimsy.space/"
    url.searchParams.append "idpjwt", Object.values(AWS.config.credentials.params.Logins)[0]

    new WebSocket url

  # Resolve with true if lazy loading succeeded
  ready: LL ->
    AWS
