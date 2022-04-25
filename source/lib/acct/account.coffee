# User account model
# depends on shared global AWS config state, so only one user at a time for now

Cognito = require "../aws/cognito"
#@ts-ignore TODO
cognito = Cognito(PACKAGE.config.cognito)

fs = require "../fs/index"

util = require "../util/index"
promiseChoke = util.promiseChoke

###*
@param AWS {AWSInterface}
###
module.exports = (AWS) ->
  # The credentials need to have been populated by cognito.
  id = AWS.config.credentials.identityId

  bucket = new AWS.S3
    params:
      Bucket: "whimsy-fs"

  refreshCredentials = promiseChoke ->
    # This has the side effect of updating the global AWS object's credentials
    cognito.cachedUser()
    .then (AWS) ->
      # Copy the updated credentials to the bucket
      bucket.config.credentials = AWS.config.credentials
    .catch console.debug

  id: id
  fs: fs.S3(id, bucket, refreshCredentials)
  logout: ->
    cognito.logout()
