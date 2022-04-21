{crudeRequire} = require "../pkg/index"

module.exports = (pkg, templates={}) ->
  Object.keys(pkg.distribution).forEach (key) ->
    if key.startsWith 'templates/'
      templateName = key
        .replace(/^templates\//, "")
        .replace(/^([a-z])|[_-]([a-z])/g, (m, a, b) ->
          (a or b).toUpperCase()
        )

      try
        templates[templateName] = crudeRequire pkg.distribution[key].content
      catch e
        console.warn e

  return templates
