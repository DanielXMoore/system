Bindable = require "../bindable"
Ergonomics = require("./util").Ergonomics

MountFS = ->
  ###*
  @type {{[key: string]: {
    subsystem: ZOSFileSystem
    handler: Function}
  }}
  ###
  mounts = {}
  #
  ###*
  @type {string[]}
  ###
  mountPaths = []

  #
  ###*
  @param a {string}
  @param b {string}
  ###
  longestToShortest = (a, b) ->
    b.length - a.length

  #
  ###*
  @param path {string}
  ###
  findMountPathsFor = (path) ->
    mountPaths.filter (p) ->
      path.startsWith p

  #
  ###*
  @param method {string}
  @return {(path: keyof FSOperations, ...params: any[]) => Promise<any>} TODO
  ###
  proxyToMount = (method) ->
    (path, params...) ->
      paths = findMountPathsFor path

      unless paths.length
        throw new Error "No mounted filesystem for #{path}"

      #
      ###* @type {string} ###
      #@ts-ignore
      mountPath = paths[0]
      #@ts-ignore
      mount = mounts[mountPath].subsystem

      subsystemPath = path.replace(mountPath, "/")

      if method is "list"
        # Remap paths when retrieving entries
        #@ts-ignore
        mount[method](subsystemPath, params...)
        .then (entries) ->
          entries.map (entry) ->
            Object.assign {}, entry,
              path: entry.path.replace("/", mountPath)
      else if method is "read"
        #@ts-ignore
        mount[method](subsystemPath, params...)
        .then (blob) ->
          if blob
            #@ts-ignore
            blob.path = path

            return blob
          return undefined
      else
        #@ts-ignore
        mount[method](subsystemPath, params...)

  #
  ###* @type {ZOSFileSystem & MountFS}###
  #@ts-ignore
  self =
    read: proxyToMount "read"
    write: proxyToMount "write"
    delete: proxyToMount "delete"
    list: proxyToMount "list"

    # S3FS has a local cache, other local systems don't because they are
    # already local. This will call clear cache on any subsystem if it exists.
    clearCache: ->
      Object.values(mounts).forEach (value) ->
        #@ts-ignore TODO: https://github.com/jashkenas/coffeescript/issues/5415
        clearCache = value.subsystem.clearCache

        if clearCache
          clearCache()

    ###*
    @type {MountFS["mount"]}
    ###
    mount: (folderPath, subsystem) ->
      #
      ###*
      Pass all subsystem events through, rewriting the path
      @param eventName {string}
      @param path {string}
      ###
      handler = (eventName, path) ->
        self.trigger eventName, path.replace("/", folderPath)

      # Remove previous subsystem handler if present
      foundMount = mounts[folderPath]
      if foundMount
        {subsystem: s, handler: h} = foundMount
        s.off "*", h

      subsystem.on "*", handler

      mounts[folderPath] = { subsystem, handler }
      mountPaths.push folderPath
      mountPaths.sort longestToShortest

      return self

  Bindable(undefined, self)
  Ergonomics(self)

  return self

module.exports = MountFS
