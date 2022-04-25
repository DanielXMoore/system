{lazyLoader} = require "../util/index"

###*
@typedef {(path: string, source: string) => PromiseLike<string>} CompilerFn
###

#
###*
@param path {string}
@param source {string}
###
identity = (
  #@ts-ignore
  path,
  source) -> Promise.resolve(source)

class CompileError extends Error
  ###*
  @param message {string}
  @param location {{
    row: number
    column: number
    text: string
    type: string
  }}
  ###
  constructor: (message, location) ->
    super(message)
    @location = location
    delete @stack

#
###*
@param path {string}
@param source {string}
@return {string}
###
compileCoffee = (path, source) ->
  try
    #@ts-ignore
    CoffeeScript.compile source,
      bare: true
      filename: path
  catch e # normalize coffeescript errors
    #@ts-ignore TODO: actual error type
    {message, location} = e
    if location
      throw new CompileError message,
        row: location.first_line
        column: location.first_column
        text: message
        type: "error"
    else
      throw e

#
###*
@param path {string}
@param source {string}
@return {string}
###
#@ts-ignore
compileMarkdown = (path, source) ->
  #@ts-ignore
  marked source

#
###*
@param path {string}
@param source {string}
@return {string}
###
compileStylus = (path, source) ->
  try
    #@ts-ignore
    stylus.render source,
      filename: path
  catch e # normalize errors
    #@ts-ignore TODO: actual error type
    if e.name is "ParseError" # stylus parse errors
      #@ts-ignore TODO: actual error type
      if match = e.message.match(/^[^:]*:(\d+):(\d+)/)
        [_, row, column] = match

        #@ts-ignore TODO: actual error type
        message = e.message.split("\n")[8] # only display error line

        throw new CompileError message,
          # Need to subtract 298 from stylus error locations because it
          # includes the function imports in the line count
          row: row - 298,
          column: column,
          text: message
          type: "error"

    throw e

#
###*
@type {{[key: string]: CompilerFn }}
###
compilers =
  css: identity
  html: identity
  js: identity
  coffee: lazyLoader(["https://danielx.net/cdn/coffee-script/1.7.1.min.js"]) compileCoffee
  md: lazyLoader(["https://danielx.net/cdn/marked/0.6.2.min.js"]) compileMarkdown
  styl: lazyLoader(["https://danielx.net/cdn/stylus/0.54.5.min.js"]) compileStylus

#
###*
@param path {string}
@param source {string}
@return {PromiseLike<string>}
###
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
  ###*
  @param ext {string}
  @param fn {CompilerFn}
  ###
  registerCompiler: (ext, fn) ->
    compilers[ext] = fn
