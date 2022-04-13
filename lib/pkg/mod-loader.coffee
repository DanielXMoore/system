# Experimental!

# Load an exported module from a remote path into the system namespace
# fs/storage.coffee -> system.fs.Storage
# This is insane and I love it
modLoad = (path, source, namespace=system) ->
  {compile, crudeRequire} = system.pkg
  {withoutAllExtensions} = system.fs

  compile(path, source)
  .then (program) ->
    exportedModule = crudeRequire program

    paths = path.split("/")
    l = paths.length
    paths.reduce (namespace, name, i) ->
      if i is l - 1
        # Strip all extensions
        name = withoutAllExtensions name

        # system/util/index.coffee -> methods on system.util
        if typeof exportedModule is "object"
          return Object.assign namespace, exportedModule
        else
          # system/fs/storage.coffee -> system.fs.Storage class
          # Titleize name
          name = name.replace /^([a-z])|[_-]([a-z])/g, (m, a, b) ->
            (a or b).toUpperCase()
  
          return namespace[name] = exportedModule
  
      return namespace[name] ||= {}
    , namespace

# Create a loader for a namespace
module.exports = (fs, basePath, namespace) ->
  (path) ->
    fs.read basePath + path
    .then (b) -> b.text()
    .then (source) ->
      modLoad path, source, namespace
