Login = require "../../views/login"

module.exports =
  ###*
  @param showUI {boolean}
  ###
  login: (showUI) ->
    new Promise (resolve, reject) ->
      Login {
        headless: !showUI
        resolve
        reject
      }
