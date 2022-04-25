# TODO: Remove unused `I` argument
#@ts-ignore
module.exports = (I={}, self={}) ->
  ###*
  @type {{[key: string]: Function[]}}
  ###
  eventCallbacks = {}

  Object.assign self,
    ###*
    @param event {string}
    @param callback {Function}
    ###
    on: (event, callback) ->
      (eventCallbacks[event] ||= []).push(callback)

      return self

    ###*
    @param event {string}
    @param callback {Function}
    ###
    off: (event, callback) ->
      if event
        eventCallbacks[event] ||= []

        if callback
          #@ts-ignore
          remove eventCallbacks[event], callback
        else
          eventCallbacks[event] = []

      return self

    ###*
    @param event {string}
    @param parameters {any[]}
    ###
    trigger: (event, parameters...) ->
      (eventCallbacks["*"] or []).forEach (callback) ->
        callback.apply(self, [event].concat(parameters))

      unless event is "*"
        (eventCallbacks[event] or []).forEach (callback) ->
          callback.apply(self, parameters)

      return self

  return self

#
###*
@template T
@param array {T[]}
@param value {T}
###
remove = (array, value) ->
  index = array.indexOf(value)

  if index >= 0
    return array.splice(index, 1)[0]

  return undefined
