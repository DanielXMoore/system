###*
@typedef {import("esbuild").Plugin} ESBuildPlugin
###

fsPromises = require "fs/promises"
path = require "path"
esbuild = require 'esbuild'
#@ts-ignore
coffeeScriptPlugin = require 'esbuild-coffeescript'
#
###* @type {() => ESBuildPlugin} ###
jadeletPlugin = require "jadelet/esbuild-plugin"
# heraPlugin = require "@danielx/hera/esbuild-plugin"
CoffeeScript = require "coffeescript"
stylus = require "stylus"

# TODO CoffeeSense destructuring
access = fsPromises.access
readFile = fsPromises.readFile

exists = (###* @type {string} ### p) ->
  access(p)
  .then ->
    true
  .catch ->
    false

#
###* @type {(extensions: string[]) => ESBuildPlugin} ###
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

      return undefined

#
###* @type {() => ESBuildPlugin} ###
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

#
###* @type {() => ESBuildPlugin} ###
stylusPlugin = ->
  name: "stylus"
  setup: (build) ->
    build.onLoad { filter: /\.styl$/ }, (args) ->
      readFile(args.path, "utf8").then (source) ->
        cssText = stylus.render source,
          #@ts-ignore TODO: Figure out how to add an overload to stylus
          filename: args.path

        contents: "module.exports = #{JSON.stringify(cssText)}"
      .catch (e) ->
        errors: [
          {
            text: e.message
          }
        ]

watch = process.argv.includes '--watch'
#@ts-ignore
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
