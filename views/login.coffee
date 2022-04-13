# Note: This is adapted from whimsy.space My Briefcase to provide a generic
# login for all whimsy.space and danielx.net apps

Account = require "/lib/acct/account"

Cognito = require "/lib/aws/cognito"
cognito = Cognito(PACKAGE.config.cognito)

{exec: compileTemplate} = require "/lib/jadelet"

Observable = require "/lib/observable"

Modal = require "/modal"

module.exports = (options={}) ->
  {description, headless, resolve, reject, title} = options

  title ?= "🔑 Log in to Whimsy.Space [DanielX.net]"
  description ?= """
    Maintain access to your files across different machines. Publish
    effortlessly to the internet. Participate in the DanielX.net community.
  """

  model =
    loading: Observable true
    state: Observable "start"
    content: Observable()
    submit: (e) ->
      e.preventDefault()
      @errorMessage ""

      if @state() is "register"
        @loading true

        if @password() is @confirmPassword()
          cognito.signUp(@email(), @password())
          .then =>
            @loading false
            @clearForm()
            @errorMessage ""
            @state "confirm"
          .catch (e) =>
            @loading false
            @errorMessage "Error: " + e.message
        else
          @errorMessage "Error: Password does not match password confirmation"
          @loading false
      else
        @loading true

        cognito.authenticate(@email(), @password())
        .then receivedCredentials
        .catch (e) =>
          console.error(e)
          @errorMessage "Error: " + e.message
        .finally =>
          @loading false

    title: title 
    description: description
    email: Observable ""
    password: Observable ""
    confirmPassword: Observable ""
    clearForm: ->
      @email ""
      @password ""
      @confirmPassword ""
    errorMessage: Observable ""
    goBack: (e) ->
      e.preventDefault()
      @errorMessage ""
      @state "start"
    goToRegister: (e) ->
      e.preventDefault()
      @state "register"
    goToLogin: (e) ->
      e.preventDefault()
      @state "login"
    logout: (e) ->
      e.preventDefault()

      @id null
      @state "start"
      cognito.logout()

  stateTemplates =
    register: compileTemplate """
      section
        p.error @errorMessage
        label
          h2 Email
          input(name="email" value=@email)
        label
          h2 Password
          input(type="password" name="password" value=@password)
        label
          h2 Confirm Password
          input(type="password" name="confirm" value=@confirmPassword)

        button.full Register
        button.top-left(click=@goBack) Back
    """

    loading: compileTemplate """
      progress
    """

    start: compileTemplate """
      section
        p.error @errorMessage
        p @description
        button.full(click=@goToLogin) Login
        button.full(click=@goToRegister) Register
    """

    confirm: compileTemplate """
      section
        p.error @errorMessage
        p A confirmation email has been sent to your address, please follow the confirmation link!
        button.full(click=@goToLogin) Next
    """

    login: compileTemplate """
      section
        p.error @errorMessage
        label
          h2 Email or Username
          input(name="email" value=@email)
        label
          h2 Password
          input(type="password" name="password" value=@password)

        button.full Sign In
        a(href="https://auth.danielx.net/forgotPassword?client_id=3fd84r6idec9iork4e9l43mp61&response_type=token&scope=aws.cognito.signin.user.admin+email+openid+phone+profile&redirect_uri=https://whimsy.space/" target="_blank") Forgot Password?
        button.top-left(click=@goBack) Back
    """

  formTemplate = compileTemplate """
    section.ws-login
      form(@submit)
        h1 @title
        @content
  """

  Observable ->
    state = model.state()
    loading = model.loading()

    if loading
      model.content stateTemplates.loading(model)
    else
      model.content stateTemplates[state](model)

  # Callback after the user has authenticate either through cached
  # credentials or by registering or signing in.
  receivedCredentials = (AWS) ->
    model.clearForm()

    resolve Account AWS

    if !headless
      Modal.hide()

  cognito.cachedUser()
  .then receivedCredentials
  .catch (e) ->
    model.loading false
    console.debug e

  # Show modal to login if not in headless mode
  if !headless
    element = formTemplate model

    Modal.show element, reject
