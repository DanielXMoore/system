require "/lib/extensions"

{api, cdn, ready} = require "/lib/aws/index"

Cognito = require "/lib/aws/cognito"

{cognito:config} = PACKAGE.config
cognito = Cognito(config)

mocha.setup
  globals: ['AWSCognito', 'AmazonCognitoIdentity', 'AWS']

# skipped for test performance, dependence on remote resources
describe.skip "AWS", ->
  it "cdn", ->
    @timeout 30000
    blob = new Blob ["heyy234"], type: "text/plain"

    cognito.authenticate("daniel+test@danielx.net", "yo yo yo")
    .then ->
      cdn blob

  it "api", ->
    @timeout 5000

    cognito.authenticate("daniel+test@danielx.net", "yo yo yo")
    .then ->
      api("")

  it "ready", ->
    ready()
