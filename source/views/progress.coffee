Template = require "../templates/progress"

Observable = require "../lib/observable"

""

module.exports = (params={}) ->
  {value, max, message} = params
  value = Observable value or 0
  max = Observable max
  message = Observable message

  element = Template
    value: value
    max: max
    message: message

  element: element
  value: value
  message: message
  max: max
