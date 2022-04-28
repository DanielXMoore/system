###*
@template {GlobalEventHandlers} T
@param element {T}
@param handler {(e:DragEvent) => void}
###
module.exports = (element, handler) ->
  # TODO: need a way to dispose / remove handlers
  element.addEventListener "dragover", cancel
  element.addEventListener "dragenter", cancel
  element.addEventListener "drop", (e) ->
    handler(e)

#
###*
@param e {Event}
###
cancel = (e) ->
  e.preventDefault()
  return false
