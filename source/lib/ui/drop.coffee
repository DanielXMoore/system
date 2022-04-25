###*
@param element {Element}
@param handler {(e:Event) => void}
###
module.exports = (element, handler) ->
  ###*
  @param e {Event}
  ###
  cancel = (e) ->
    e.preventDefault()
    return false

  element.addEventListener "dragover", cancel
  element.addEventListener "dragenter", cancel
  element.addEventListener "drop", (e) ->
    handler(e)
