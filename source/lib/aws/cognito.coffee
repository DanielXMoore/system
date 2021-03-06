###
Cognito info:

JS SDK: https://github.com/aws/amazon-cognito-identity-js
Pricing: https://aws.amazon.com/cognito/pricing/
Adding Social Identity Providers: http://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pools-social.html

https://whimsy.auth.us-east-1.amazoncognito.com/oauth2/idpresponse
###

_LL = require "./_lazy"

module.exports = ({identityPoolId, poolData}) ->
  userPool = null

  # Creating user pool and setting region must happen after lazy loading
  _init = ->
    userPool ?= new AWSCognito.CognitoIdentityServiceProvider.CognitoUserPool(poolData)
    # Region needs to be set if not already set previously elsewhere.
    AWS.config.region ?= 'us-east-1'

  # Wrap lazy loader function to call _init logic
  LL = (fn) ->
    _LL (args...) ->
      _init()
      fn.apply(this, args)

  configureAWSFor = (session, resolve, reject) ->
    token = session.getIdToken().getJwtToken()

    loginKey = "cognito-idp.us-east-1.amazonaws.com/#{poolData.UserPoolId}"
    loginsConfig = {}
    loginsConfig[loginKey] = token

    AWS.config.credentials = new AWS.CognitoIdentityCredentials
      IdentityPoolId: identityPoolId
      Logins: loginsConfig

    # refreshes credentials
    AWS.config.credentials.refresh (error) ->
      if error
        reject error
      else
        # TODO: AWS is global :(
        # Probably doesn't matter because ZineOS is single user
        resolve AWS

      return
    return

  mapAttributes = (attributes) ->
    return unless attributes

    Object.keys(attributes).map (name) ->
      value = attributes[name]

      new AWSCognito.CognitoIdentityServiceProvider.CognitoUserAttribute
        Name: name
        Value: value

  self =
    signUp: LL (username, password, attributes) ->
      attributeList = mapAttributes(attributes)

      new Promise (resolve, reject) ->
        userPool.signUp username, password, attributeList, null, (err, result) ->
          if err
            return reject(err)

          cognitoUser = result.user

          # User will need to confirm email address
          resolve cognitoUser

    authenticate: LL (username, password) ->
      authenticationData =
        Username : username
        Password : password

      authenticationDetails = new AWSCognito.CognitoIdentityServiceProvider.AuthenticationDetails(authenticationData)

      userData =
        Username : username
        Pool : userPool

      cognitoUser = new AWSCognito.CognitoIdentityServiceProvider.CognitoUser(userData)

      new Promise (resolve, reject) ->
        cognitoUser.authenticateUser authenticationDetails,
          onSuccess: (session) ->
            configureAWSFor session, resolve, reject
          onFailure: reject

    cachedUser: LL ->
      new Promise (resolve, reject) ->
        cognitoUser = userPool.getCurrentUser()

        if cognitoUser
          cognitoUser.getSession (err, session) ->
            if err
              reject err
              return

            configureAWSFor(session, resolve, reject)
        else
          setTimeout ->
            reject new Error "No cached user"

    logout: ->
      # Clear global AWS credentials if present
      delete AWS?.config.credentials

      try # return if we can't access local storage
        localStorage
      catch
        return

      Object.keys(localStorage).filter (key) ->
        key.match /^CognitoIdentityServiceProvider/
      .forEach (key) ->
        delete localStorage[key]
      return
