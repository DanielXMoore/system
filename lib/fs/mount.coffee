Bindable = require "../bindable"

{Ergonomics} = require "./util"

module.exports = () ->
  mounts = {}
  mountPaths = []

  longestToShortest = (a, b) ->
    b.length - a.length

  findMountPathsFor = (path) ->
    mountPaths.filter (p) ->
      path.startsWith p

  proxyToMount = (method) ->
    (path, params...) ->
      mountPaths = findMountPathsFor path

      unless mountPaths.length
        throw new Error "No mounted filesystem for #{path}"

      [mountPath] = mountPaths
      mount = mounts[mountPath].subsystem

      subsystemPath = path.replace(mountPath, "/")

      if method is "list"
        # Remap paths when retrieving entries
        mount[method](subsystemPath, params...)
        .then (entries) ->
          entries.map (entry) ->
            Object.assign {}, entry, 
              path: entry.path.replace("/", mountPath)
      else if method is "read"
        mount[method](subsystemPath, params...)
        .then (blob) ->
          if blob
            blob.path = path

            return blob
      else
        mount[method](subsystemPath, params...)

  self =
    read: proxyToMount "read"
    write: proxyToMount "write"
    delete: proxyToMount "delete"
    list: proxyToMount "list"

    # S3FS has a local cache, other local systems don't because they are
    # already local. This will call clear cache on any subsystem if it exists.
    clearCache: ->
      Object.keys(mounts).forEach (key) ->
        mounts[key].subsystem.clearCache?()

    mount: (folderPath, subsystem) ->
      # Pass all subsystem events through, rewriting the path
      handler = (eventName, path) ->
        self.trigger eventName, path.replace("/", folderPath)

      # Remove previous subsystem handler if present
      if mounts[folderPath]
        {subsystem: s, handler: h} = mounts[folderPath]
        s.off "*", h

      subsystem.on "*", handler

      mounts[folderPath] = { subsystem, handler }
      mountPaths.push folderPath
      mountPaths.sort longestToShortest

      return self

  Bindable(undefined, self)
  Ergonomics(self)

  return self
