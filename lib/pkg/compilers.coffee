{lazyLoader} = require "../util/index"

identity = (path, source) -> source

CompileError = (message, location) ->
  @location = location
  @message = message
  delete this.stack

CompileError.prototype = Object.create(new Error)

compilers =
  css: identity
  html: identity
  js: identity
  coffee: lazyLoader(["https://danielx.net/cdn/coffee-script/1.7.1.min.js"]) (path, source) ->
    try
      CoffeeScript.compile source, 
        bare: true
        filename: path
    catch e # normalize coffeescript errors
      {message, location} = e
      if location
        throw new CompileError message,
          row: location.first_line
          column: location.first_column
          text: message
          type: "error"
      else
        throw e
  md: lazyLoader(["https://danielx.net/cdn/marked/0.6.2.min.js"]) (path, source) ->
    marked source
  styl: lazyLoader(["https://danielx.net/cdn/stylus/0.54.5.min.js"]) (path, source) ->
    try
      stylus.render source,
        filename: path
    catch e # normalize errors
      if e.name is "ParseError" # stylus parse errors
        if match = e.message.match(/^[^:]*:(\d+):(\d+)/)
          [_, row, column] = match

          message = e.message.split("\n")[8] # only display error line

          throw new CompileError message,
            # Need to subtract 298 from stylus error locations because it 
            # includes the function imports in the line count
            row: row - 298,
            column: column,
            text: message
            type: "error"
      else
        throw e

compile = (path, source) ->
  {extensionFor} = require "../fs/util"

  extension = extensionFor(path)

  Promise.resolve()
  .then ->
    if compiler = compilers[extension]
      return compiler(path, source)
    else
      throw new Error "Couldn't compile '#{path}'. No compiler for '.#{extension}'"

module.exports =
  compile: compile
  CompileError: CompileError
  registerCompiler: (ext, fn) ->
    compilers[ext] = fn
