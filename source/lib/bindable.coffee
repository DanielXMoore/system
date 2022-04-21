# TODO: Remove unused `I` argument
module.exports = (I={}, self={}) ->
  eventCallbacks = {}

  Object.assign self,
    on: (event, callback) ->
      eventCallbacks[event] ||= []
      eventCallbacks[event].push(callback)

      return self

    off: (event, callback) ->
      if event
        eventCallbacks[event] ||= []

        if callback
          remove eventCallbacks[event], callback
        else
          eventCallbacks[event] = []

      return self

    trigger: (event, parameters...) ->
      (eventCallbacks["*"] or []).forEach (callback) ->
        callback.apply(self, [event].concat(parameters))

      unless event is "*"
        (eventCallbacks[event] or []).forEach (callback) ->
          callback.apply(self, parameters)

      return self

  return self

remove = (array, value) ->
  index = array.indexOf(value)

  if index >= 0
    array.splice(index, 1)[0]
