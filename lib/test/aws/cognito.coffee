Cognito = require "/lib/aws/cognito"

{cognito:config} = PACKAGE.config
cognito = Cognito(config)

S3FS = require "/lib/fs/s3"

mocha.setup
  globals: ['AWSCognito', 'AmazonCognitoIdentity', 'AWS']

# Skipped for performance
describe "Cognito", ->
  describe.skip "Remote calls", ->
    it "should authenticate", ->
      @timeout 5000
      # Sign up creates a user account and sends an email to the given address
      # Test creation by uncommenting this line:
      #
      # Cognito().signUp("daniel+test@danielx.net", "yo yo yo")
  
      # The user will need to confirm their address before logging in
      console.log config
      cognito.authenticate("daniel+test@danielx.net", "yo yo yo")
  
    it "should reject with invalid password", (done) ->
      cognito.authenticate("daniel+test@danielx.net", "not the password")
      .catch (e) ->
        assert.equal e.code, "NotAuthorizedException"
        assert.equal e.statusCode, 400
        done()
  
      return

  it "shouldn't throw an error on logout even when sandboxed", ->
    cognito.logout()

# Skipped for performance
describe.skip "S3FS", ->
  it "should auth with cognito and gate api requests to the same path", ->
    @timeout 5000

    cognito.authenticate("daniel+test@danielx.net", "yo yo yo")
    .then ->
      id = AWS.config.credentials.identityId

      bucket = new AWS.S3
        params:
          Bucket: "whimsy-fs"
  
      refreshCredentials = ->
        # This has the side effect of updating the global AWS object's credentials
        cognito.cachedUser()
        .then (AWS) ->
          # Copy the updated credentials to the bucket
          bucket.config.credentials = AWS.config.credentials
        .catch console.debug
  
      fs = S3FS(id, bucket, refreshCredentials)

      # View in network tab that only one request is in flight per dir
      fs.list("/")
      fs.list("/")
      fs.list("/")
      fs.list("/")
      fs.list("/")
      fs.list("/")
      fs.list("/")
      fs.list("/")
      fs.list("/")
      fs.list("/")
      fs.list("/")

      fs.list("/public")
      fs.list("/public")
      fs.list("/public")
