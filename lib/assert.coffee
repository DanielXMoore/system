module.exports = (condition, message) ->
  throw new Error message unless condition
