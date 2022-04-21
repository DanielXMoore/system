Login = require "../../views/login"

module.exports =
  login: (showUI) ->
    new Promise (resolve, reject) ->
      Login {
        headless: !showUI
        resolve
        reject
      }
