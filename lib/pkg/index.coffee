###
`pkg` holds utilities for bundling and launching packages as standalone blobs or
in iframes.

###

htmlToBlob = (htmlString) ->
  new Blob [htmlString], type: "text/html; charset=utf-8"

metaTag = (name, content) ->
  "<meta name=#{JSON.stringify(name)} content=#{JSON.stringify(content)}>"

linkTag = (rel, href) ->
  "<link rel=#{JSON.stringify(rel)} href=#{JSON.stringify(href)}>"

{lazyLoader} = require "../util/index"

uglifyLoaded = lazyLoader ["https://danielx.net/cdn/uglify/3.0.0.min.js"]

latestRequire = require "./require"

###
Construct an HTML file for the package.

The default behavior is to load the package's entry point but
that can be modified enter from any file in the package.

It also adds remote dependencies to the HTML head and wraps with
the system launch if present.

This is designed to be simple and general, any magic binding should happen in
the `!system` layer. Here we are only concerned with html tags and setting up
the package with `require`.

`opts`
additionalDependencies: array of additional dependency scripts to include in
the html source. Useful for things like testing libraries, doc formatting, etc.
code: The code snippet to run, defaults to requiring the default package
entry point.
stylesheets: array of urls to add as stylesheet link tags
systemConfig: configuration parameters for the system runtime.
###
htmlForPackage = (pkg, opts={}) ->
  metas = [
    '<meta charset="utf-8">'
    '<meta name="viewport" content="width=device-width, initial-scale=1.0">'
  ]

  {config, progenitor} = pkg
  config ?= {}

  {code, systemConfig} = opts

  # by default launch from the packages entry point or main file.
  code ?= """
    require('./#{pkg.entryPoint or "main"}');
  """
  code = systemWrap(pkg, code, systemConfig)

  {title, description, lang, iconURL, manifest} = config

  if lang
    langFragment =  " lang=#{JSON.stringify(lang)}"
  else
    langFragment = ""

  if title
    metas.push "<title>#{title}</title>"

  if description
    metas.push metaTag "description", description.replace("\n", " ")

  if iconURL
    metas.push linkTag "shortcut icon", iconURL

  if manifest
    metas.push linkTag "manifest", "./manifest.webmanifest"

  # Progenitor link can be used to for a built-in "Edit this!" feature
  # TODO: Should url be href?
  url = pkg.progenitor?.url
  if url
    metas.push linkTag "progenitor", url

  (pkg.stylesheets || []).concat(opts.stylesheets || []).forEach (href) ->
    metas.push linkTag "stylesheet", href

  htmlToBlob """
    <!DOCTYPE html>
    <html#{langFragment}>
      <head>
        #{metas.join("\n    ")}
        #{dependencyScripts(opts.additionalDependencies, pkg.remoteDependencies)}
      </head>
      <body>
        <script>
          #{latestRequire.packageWrapper(pkg, code)}
        <\/script>
      </body>
    </html>
  """

dependencyScripts = (additionalDependencies=[], remoteDependencies=[]) ->
  additionalDependencies.concat(remoteDependencies).map (src) ->
    "<script src=#{JSON.stringify(src)}><\/script>"
  .join("\n")

systemWrap = (pkg, code, opts={}) ->
  # The !system package self launches if detected
  # the `config` param is the host's config, which is returned from `ready`
  # on the host.
  if pkg.dependencies?["!system"]
    """
      require("!system").launch(#{JSON.stringify(opts)}, function(config) {
        #{code}
      });
    """
  else
    code

###
Execute a source code program within an environment.
###
exec = (program, env={}, context) ->
  args = Object.keys(env)
  values = args.map (name) -> env[name]

  return Function(args..., program).apply(context, values)

###
Execute a single source program with no dependencies and return what it exports.
###
crudeRequire = (program) ->
  env =
    module:
      exports: {}

  exec(program, env, env.module)

  return env.module.exports

minifyPackage = uglifyLoaded (pkg, logger) ->
  initialSize = JSON.stringify(pkg).length

  # Shallow Copy
  pkg = Object.assign {}, pkg

  # Remove source files
  delete pkg.source

  dist = pkg.distribution = Object.assign {}, pkg.distribution
  Object.keys(dist).forEach (name) ->
    # Remove test files from distribution
    if name.match /^test\/|\/test\//
      delete dist[name]
    # Remove empty files
    file = dist[name]
    if !file or !file.content
      delete dist[name]
      return

    # Minify distribution files
    {code} = UglifyJS.minify file.content,
      toplevel: true
    if code
      dist[name] =
        content: code
    else
      delete dist[name]

  # Minify dependencies
  Promise.all Object.keys(pkg.dependencies or {}).map (name) ->
    minifyPackage(pkg.dependencies[name], logger).then (m) ->
      pkg.dependencies[name] = m
  .then ->
    minSize = JSON.stringify(pkg).length
    logger?.log "Minified #{pkg.config.name}: #{initialSize} -> #{minSize} (#{((1 - minSize / initialSize)*100).toFixed(1)}% reduction)" 

    return pkg

module.exports = Object.assign {}, require("./compilers"),
  crudeRequire: crudeRequire
  exec: exec
  htmlForPackage: htmlForPackage
  Require: require "./require"
  jsForPackage: (pkg, globalName, customCode) ->
    globalName ?= pkg.config.name
    customCode ?= "#{globalName} = require('./main')"
    require.packageWrapper(pkg, customCode)
  minify: minifyPackage
  ModLoader: require "./mod-loader"

# TODO: This was extracted from the old editor, we can use it to split up
# published docs and html files to require a shared remote package rather
# than bundling inline of every published artifact.
# TODO: preload package json as="fetch" when exploring this again.
# https://developer.mozilla.org/en-US/docs/Web/HTML/Preloading_content
remotePackageLauncher = (pkg, url) ->
  """
    xhr = new XMLHttpRequest;
    url = #{JSON.stringify(url)};
    xhr.open("GET", url, true);
    xhr.responseType = "json";
    xhr.onload = function() {
      (function(PACKAGE) {
        var src = #{JSON.stringify(PACKAGE.dependencies.require.distribution.main.content)};
        var Require = new Function("PACKAGE", "return " + src)({distribution: {main: {content: src}}});
        var require = Require.generateFor(PACKAGE);
        require('./' + PACKAGE.entryPoint);
      })(xhr.response)
    };
    xhr.send();
  """
