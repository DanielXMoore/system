{lazyLoader} = require "../util/index"

module.exports = lazyLoader [
  # TODO: Figure out a good cdn for these because they are chewing through bandwidth
  # jsdelivr looks promising but these don't seem to work...
  #   "https://cdn.jsdelivr.net/npm/amazon-cognito-auth-js@1.3.3/dist/aws-cognito-sdk.min.js"
  #   "https://cdn.jsdelivr.net/npm/amazon-cognito-identity-js@5.1.0/dist/amazon-cognito-identity.min.js"

  "https://danielx.whimsy.space/cdn/cognito/sdk.min.js"
  "https://danielx.whimsy.space/cdn/cognito/identity.min.js"
  "https://sdk.amazonaws.com/js/aws-sdk-2.7.20.min.js"
]
