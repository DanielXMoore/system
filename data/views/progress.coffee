Observable = require "../../lib/observable"

module.exports = model =
  max: 1
  value: Observable 0.25

setInterval ->
  model.value.increment(0.01)
, 100
