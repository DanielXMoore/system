{access, readFile} = require "fs/promises"
path = require "path"
esbuild = require 'esbuild'
coffeeScriptPlugin = require 'esbuild-coffeescript'
jadeletPlugin = require "jadelet/esbuild-plugin"
# heraPlugin = require "@danielx/hera/esbuild-plugin"
CoffeeScript = require "coffeescript"
stylus = require "stylus"

exists = (p) ->
  access(p)
  .then ->
    true
  .catch ->
    false

extensionResolverPlugin = (extensions) ->
  name: "extension-resolve"
  setup: (build) ->
    # For relatiev requires that don't contain a '.'
    build.onResolve { filter: /\/[^.]*$/ }, (r) ->
      for extension in extensions
        {path: resolvePath, resolveDir} = r
        p = path.join(resolveDir, resolvePath + ".#{extension}")

        # see if a .coffee file exists
        found = await exists(p)
        if found
          return path: p

      return

csonPlugin = ->
  name: "cson"
  setup: (build) ->
    build.onLoad { filter: /\.cson$/ }, (args) ->
      readFile(args.path, 'utf8').then (source) ->
        contents: "module.exports = " + CoffeeScript.compile source, bare: true, header: false
      .catch (e) ->
        errors: [
          {
            text: e.message
          }
        ]

stylusPlugin = ->
  name: "stylus"
  setup: (build) ->
    build.onLoad { filter: /\.styl$/ }, (args) ->
      readFile(args.path, "utf8").then (source) ->
        cssText = stylus.render source,
          filename: args.path

        contents: "module.exports = #{JSON.stringify(cssText)}"
      .catch (e) ->
        errors: [
          {
            text: e.message
          }
        ]

watch = process.argv.includes '--watch'
minify = !watch || process.argv.includes '--minify'
sourcemap = true

esbuild.build({
  entryPoints: ['source/main.coffee']
  # tsconfig: "./tsconfig.json"
  bundle: true
  sourcemap
  minify: false
  watch
  define:
    global: "window"
  platform: 'browser'
  outfile: 'dist/system.js'
  globalName: 'system'
  plugins: [
    extensionResolverPlugin ["coffee", "jadelet"]
    coffeeScriptPlugin
      bare: true
      inlineMap: sourcemap
    jadeletPlugin()
    csonPlugin()
    stylusPlugin()
    # heraPlugin
  ]
}).catch -> process.exit 1
