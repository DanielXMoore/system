Bindable = require "../bindable"

# FS Wrapper to a pixie package
# source is mounted as the root
#
# opts.persist receive the package object and return a promise that
# is fulfilled when the package is persisted
#
# opts.compile receives a blob and returns a promise with a string of the
# compiled output
module.exports = (pkg, opts={}) ->
  notify = (eventType, path) ->
    (result) ->
      self.trigger eventType, path
      return result

  persist = opts.persist or noop
  compile = opts.compile or -> Promise.resolve()

  compileAndWrite = (path, blob) ->
    writeSource = blob.text()
    .then (text) ->
      srcPath = sourcePath(path)
      pkg.source[srcPath] =
        content: text
        type: blob.type or ""
        path: srcPath

    # Compilers expect blob to be annotated with the path
    blob.path = path

    writeCompiled = compile(blob)
    .then (compiledSource) ->
      if typeof compiledSource is "string"
        pkg.distribution[withoutAllExtensions(sourcePath(path))] =
          content: compiledSource
      else
        console.warn "Can't package files like #{path} yet", compiledSource

    Promise.all [writeSource, writeCompiled]
    .then persist

  self =
    # Read a blob from a path
    read: (path) ->
      entry = pkg.source[sourcePath(path)]
      throw new Error "File not found at: #{path}" unless entry

      {content, type} = entry
      type ?= ""

      blob = new Blob [content],
        type: type

      Promise.resolve blob
      .then notify "read", path

    # Write a blob to a path
    write: (path, blob) ->
      compileAndWrite(path, blob)
      .then notify "write", path

    # Delete a file at a path
    delete: (path) ->
      Promise.resolve()
      .then ->
        delete pkg.source[sourcePath(path)]
      .then notify "delete", path

    # List files and folders in a directory
    list: (dir) ->
      sourceDir = sourcePath(dir)

      Promise.resolve()
      .then ->
        Object.keys(pkg.source).filter (path) ->
          path.indexOf(sourceDir) is 0
        .map (path) ->
          path: "/" + path
          relativePath: path.replace(sourceDir, "")
          type: pkg.source[path].type or ""
      .then (files) ->
        folderPaths = {}

        files = files.filter (file) ->
          if file.relativePath.match /\// # folder
            folderPath = file.relativePath.replace /\/.*$/, "/"
            folderPaths[folderPath] = true
            return
          else
            return file

        folders = Object.keys(folderPaths).map (folderPath) ->
          FolderEntry folderPath, dir

        return folders.concat(files)
      .then notify "list", dir

  Bindable undefined, self

# Utils

FolderEntry = (path, prefix) ->
  folder: true
  path: prefix + path
  relativePath: path

# Keys in the package's source object don't begin with slashes
sourcePath = (path) ->
  path.replace(/^\//, "")

# Strip out extension suffixes
withoutAllExtensions = (path) ->
  path.replace(/\.[^\/]*$/,"")

noop = ->
