# Scratch pad for pkg experiments

  keyString = (key) ->
    if key.match /^[A-Za-z]+[A-Za-z0-9]*$/
      key
    else
      JSON.stringify key

  # Converts a package to a string with files to require as functions 
  # It's like JSON but with functions for distribution files. This is intended
  # to be embedded directly in a script tag or a .js file.
  # Notes: This worked but didn't result in a smaller size. It may be necessary
  # for use in other contexts where we need to eliminate `Function` constructor
  # link in Chrome Apps or other restricted environments. Putting on the shelf
  # for now.
  functionalize = (pkg) ->
    "{" + keys(pkg).map (key) ->
      v = pkg[key]
      if key is "distribution"
        value = "{" + keys(v).map (path) ->
          # TODO?: add parameters to avoid Function constructor?
          "#{keyString(path)}:function(){#{v[path].content}}"
        .join(",\n") + "}"
      else if key is "dependencies"
        value = "{" + keys(v).map (dep) ->
          "#{keyString(dep)}:#{functionalize(v[dep])}"
        .join(",\n") + "}"
      else
        value = JSON.stringify v, null, 2

      "#{keyString(key)}: #{value}"
    .join(",\n") + "}"
