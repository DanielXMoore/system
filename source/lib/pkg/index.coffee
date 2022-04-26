###*
`pkg` holds utilities for bundling and launching packages as standalone blobs or
in iframes.

###

#
###*
@param htmlString {BlobPart} String of html.
###
htmlToBlob = (htmlString) ->
  new Blob [htmlString], type: "text/html; charset=utf-8"

#
###*
@param name {string}
@param content {string}
###
metaTag = (name, content) ->
  "<meta name=#{JSON.stringify(name)} content=#{JSON.stringify(content)}>"

#
###*
@param rel {string}
@param href {string}
###
linkTag = (rel, href) ->
  "<link rel=#{JSON.stringify(rel)} href=#{JSON.stringify(href)}>"

{lazyLoader} = require "../util/index"

uglifyLoaded = lazyLoader ["https://danielx.net/cdn/uglify/3.0.0.min.js"]

latestRequire = require "./require2"

#
###*
Construct an HTML file for the package.

The default behavior is to load the package's entry point but
that can be modified enter from any file in the package.

It also adds remote dependencies to the HTML head and wraps with
the system launch if present.

This is designed to be simple and general, any magic binding should happen in
the `!system` layer. Here we are only concerned with html tags and setting up
the package with `require`.

@param pkg {any} TODO: pkg config type

@param opts {{
  additionalDependencies?: string[] // array of additional dependency scripts to include in the html source. Useful for things like testing libraries, doc formatting, etc.
  code?: string // The code snippet to run, defaults to requiring the default package entry point.
  stylesheets?: string[] // array of urls to add as stylesheet link tags
  systemConfig?: any // configuration parameters for the system runtime.
}}

###
htmlForPackage = (pkg, opts={}) ->
  metas = [
    '<meta charset="utf-8">'
    '<meta name="viewport" content="width=device-width, initial-scale=1.0">'
  ]

  {config} = pkg
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

  (pkg.stylesheets || []).concat(opts.stylesheets || []).forEach (###* @type {string} ### href) ->
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

#
###*
@param additionalDependencies {string[]}
@param remoteDependencies {string[]}
###
dependencyScripts = (additionalDependencies=[], remoteDependencies=[]) ->
  additionalDependencies.concat(remoteDependencies).map (src) ->
    "<script src=#{JSON.stringify(src)}><\/script>"
  .join("\n")

#
###*
@param pkg {Package}
@param code {string}
@param opts {LaunchOpts}
###
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

#
###*
Execute a source code program within an environment.

@param program {string}
@param [env] {{[key: string]: any}}
@param [context] {any}
###
exec = (program, env={}, context) ->
  args = Object.keys(env)
  values = args.map (name) -> env[name]

  return Function(args..., program).apply(context, values)

#
###*
Execute a single source program with no dependencies and return what it exports.

@param program {string}
@return {any}
###
crudeRequire = (program) ->
  env =
    module:
      exports: {}

  exec(program, env, env.module)

  return env.module.exports

#
###*
@param pkg {Package}
@param logger {Logger}
@return {Promise<Package>}
###
_minifyPackage = (pkg, logger) ->
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
    #@ts-ignore TODO: Find better way to reference lazy loaded types rather than global
    {code} = UglifyJS.minify file.content,
      toplevel: true
    if code
      dist[name] =
        content: code
    else
      delete dist[name]

  # Minify dependencies
  Promise.all Object.entries(pkg.dependencies or {}).map ([name, dep]) ->
    minifyPackage(dep, logger).then (m) ->
      pkg.dependencies[name] = m
  .then ->
    minSize = JSON.stringify(pkg).length
    logger?.log "Minified #{pkg.config.name}: #{initialSize} -> #{minSize} (#{((1 - minSize / initialSize)*100).toFixed(1)}% reduction)"

    return pkg

minifyPackage = uglifyLoaded _minifyPackage

#
###*
@param pkg {Package}
@param globalName {string}
@param customCode {string}
###
jsForPackage = (pkg, globalName, customCode) ->
  if pkg.config.name
    globalName ?= pkg.config.name
  customCode ?= "#{globalName} = require('./main')"

  latestRequire.packageWrapper(pkg, customCode)

module.exports = Object.assign {}, require("./compilers"),
  crudeRequire: crudeRequire
  exec: exec
  htmlForPackage: htmlForPackage
  Require: latestRequire
  jsForPackage: jsForPackage
  minify: minifyPackage
  ModLoader: require "./mod-loader"
