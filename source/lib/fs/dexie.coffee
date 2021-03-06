Bindable = require "../bindable"

FolderEntry = (path, prefix) ->
  folder: true
  path: prefix + path
  relativePath: path

# DexieDB Containing our FS
DexieFSDB = (dbName='fs') ->
  db = new Dexie dbName

  db.version(1).stores
    files: 'path, blob, size, type, createdAt, updatedAt'

  return db

# FS Wrapper to Dexie database
module.exports = (dbName='fs') ->
  db = DexieFSDB(dbName)

  Files = db.files

  notify = (eventType, path) ->
    (result) ->
      self.trigger eventType, path
      return result

  self =
    # Read a blob from a path
    read: (path) ->
      Files.get(path)
      .then (result) ->
        result?.blob
      .then notify "read", path

    # Write a blob to a path
    write: (path, blob) ->
      throw new Error "Can only write blobs to the file system" unless blob instanceof Blob
      now = +new Date

      Files.put
        path: path
        blob: blob
        size: blob.size
        type: blob.type
        createdAt: now
        updatedAt: now
      .then notify "write", path

    # Delete a file at a path
    delete: (path) ->
      Files.delete(path)
      .then notify "delete", path

    # List files and folders in a directory
    list: (dir) ->
      Files.where("path").startsWith(dir).toArray()
      .then (files) ->
        folderPaths = {}

        files = files.filter (file) ->
          file.relativePath = file.path.replace(dir, "")

          if file.relativePath.match /\// # folder
            folderPath = file.relativePath.replace /\/.*$/, "/"
            folderPaths[folderPath] = true
            return
          else
            return file

        folders = Object.keys(folderPaths).map (folderPath) ->
          FolderEntry folderPath, dir

        return folders.concat(files)

  Bindable(undefined, self)
