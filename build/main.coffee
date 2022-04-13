esbuild = require 'esbuild'
coffeeScriptPlugin = require 'esbuild-coffeescript'
# heraPlugin = require "@danielx/hera/esbuild-plugin"

watch = process.argv.includes '--watch'
minify = !watch || process.argv.includes '--minify'
sourcemap = true

esbuild.build({
  entryPoints: ['main.coffee']
  # tsconfig: "./tsconfig.json"
  bundle: true
  sourcemap
  minify
  watch
  platform: 'node'
  outfile: 'dist/main.js'
  plugins: [
    coffeeScriptPlugin
      bare: true
      inlineMap: sourcemap
    # heraPlugin
  ]
}).catch -> process.exit 1
