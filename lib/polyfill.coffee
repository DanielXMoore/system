startsWith = (search, rawPos) ->
  if rawPos > 0
    pos = rawPos|0
  else
    pos = 0

  @substring(pos, pos + search.length) is search

endsWith = (search, l) ->
  length = @length
  if l is undefined or l > length
    l = length

  @substring(l - search.length, l) is search

String::endsWith ?= endsWith
String::startsWith ?= startsWith

# Export for testing
module.exports =
  startsWith: startsWith
  endsWith: endsWith
