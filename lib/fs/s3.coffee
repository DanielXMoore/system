Bindable = require "../bindable"

{deprecationWarning, promiseChoke} = require "../util/index"

pinvoke = (object, method, params...) ->
  new Promise (resolve, reject) ->
    object[method] params..., (err, result) ->
      if err
        reject err
        return

      resolve result

delimiter = "/"

module.exports = (id, bucket, refreshCredentials) ->
  refreshCredentials ?= -> Promise.reject new Error "No method given to refresh credentials automatically"
  refreshCredentialsPromise = Promise.resolve()

  do (oldPromiseInvoke=pinvoke) ->
    pinvoke = (args...) ->
      # Guard for expired credentials
      refreshCredentialsPromise.then ->
        oldPromiseInvoke.apply(null, args)
      .catch (e) ->
        if e.code is "CredentialsError"
          console.info "Refreshing credentials after CredentialsError", e
          refreshCredentialsPromise = refreshCredentials()

          refreshCredentialsPromise.then ->
            # Retry calls after refreshing expired credentials
            oldPromiseInvoke.apply(null, args)
        else
          throw e

  localCache = {}
  metaCache = {}

  uploadToS3 = (bucket, key, file, options={}) ->
    {cacheControl} = options

    cacheControl ?= 0

    # Optimistically Cache
    localCache[key] = file
    metaCache[key] =
      ContentType: file.type
      LastModified: new Date

    pinvoke bucket, "putObject",
      Key: key
      ContentType: file.type
      Body: file
      CacheControl: "max-age=#{cacheControl}"

  getRemote = (bucket, key) ->
    cachedItem = localCache[key]

    if cachedItem
      if cachedItem instanceof Blob
        return Promise.resolve(cachedItem)
      else
        return Promise.reject(cachedItem)

    pinvoke bucket, "getObject",
      Key: key
    .then (data) ->
      {Body, ContentType} = data

      new Blob [Body],
        type: ContentType
    .then (data) ->
      localCache[key] = data
    .catch (e) ->
      # Cache Not Founds too, since that's often what is slow
      localCache[key] = e
      throw e

  deleteFromS3 = (bucket, key) ->
    localCache[key] = new Error "Not Found"
    delete metaCache[key]

    pinvoke bucket, "deleteObject",
      Key: key

  list = promiseChoke (dir) ->
    prefix = "#{id}#{dir}"

    pinvoke bucket, "listObjects",
      Prefix: prefix
      Delimiter: delimiter
    .then (result) ->
      results = result.CommonPrefixes.map (p) ->
        FolderEntry p.Prefix, id, prefix
      .concat result.Contents.map (o) ->
        FileEntry o, id, prefix, bucket
      .map (entry) ->
        fetchMeta(entry, bucket)

      Promise.all results

  fetchFileMeta = (key, bucket) ->
    cachedItem = metaCache[key]

    if cachedItem
      return Promise.resolve(cachedItem)

    pinvoke bucket, "headObject",
      Key: key
    .then (result) ->
      metaCache[key] = result

      return result

  fetchMeta = (entry, bucket) ->
    Promise.resolve()
    .then ->
      return entry if entry.folder

      fetchFileMeta(entry.remotePath, bucket)
      .then (meta) ->
        entry.type = meta.ContentType
        entry.updatedAt = new Date(meta.LastModified)

        return entry

  notify = (eventType, path) ->
    (result) ->
      self.trigger eventType, path
      return result

  FolderEntry = (path, id, prefix) ->
    folder: true
    path: path.replace(id, "")
    relativePath: path.replace(prefix, "")
    remotePath: path

  FileEntry = (object, id, prefix, bucket) ->
    path = object.Key

    entry =
      path: path.replace(id, "")
      relativePath: path.replace(prefix, "")
      remotePath: path
      size: object.Size

    return entry

  self = Object.assign Bindable(),
    clearCache: ->
      localCache = {}
      metaCache = {}

    read: (path) ->
      unless path.startsWith delimiter
        path = delimiter + path

      key = "#{id}#{path}"

      getRemote(bucket, key)
      .then notify "read", path

    write: (path, blob, options) ->
      unless path.startsWith delimiter
        path = delimiter + path

      key = "#{id}#{path}"

      uploadToS3 bucket, key, blob, options
      .then notify "write", path

    delete: (path) ->
      unless path.startsWith delimiter
        path = delimiter + path

      key = "#{id}#{path}"

      deleteFromS3 bucket, key
      .then notify "delete", path

    list: (dir="/") ->
      unless dir.startsWith delimiter
        dir = "#{delimiter}#{dir}"

      unless dir.endsWith delimiter
        dir = "#{dir}#{delimiter}"

      list dir
      .then notify "list", dir
