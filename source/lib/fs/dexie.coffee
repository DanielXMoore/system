Bindable = require "../bindable"

Dexie = require("dexie").Dexie

#
###*
@param path {string}
@param prefix {string}

###
FolderEntry = (path, prefix) ->
  folder: true
  path: prefix + path
  relativePath: path

#
###*
DexieDB Containing our FS
@return {Dexie & {
  files: import("dexie").Table<{
    path: string
    blob: Blob
    size: number
    type: string
    createdAt: number
    updatedAt: number
  }>
}}
###
DexieFSDB = (dbName='fs') ->
  db = new Dexie dbName

  db.version(1).stores
    files: 'path, blob, size, type, createdAt, updatedAt'

  #@ts-ignore
  return db

# FS Wrapper to Dexie database
DexieFS = (dbName='fs') ->
  db = DexieFSDB(dbName)

  Files = db.files

  #
  ###*
  @param eventType {string}
  @param path {string}
  @return {<T>(result: T) => T}
  ###
  notify = (eventType, path) ->
    (result) ->
      self.trigger eventType, path
      return result

  #
  ###*
  @type {ZOSFileSystem & Bindable}
  ###
  #@ts-ignore
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
          relativePath = file.path.replace(dir, "")

          if relativePath.match /\// # folder
            folderPath = relativePath.replace /\/.*$/, "/"
            #@ts-ignore TODO
            folderPaths[folderPath] = true
            return
          else
            #@ts-ignore TODO
            file.relativePath = relativePath
            return file

        folders = Object.keys(folderPaths).map (folderPath) ->
          FolderEntry folderPath, dir

        #@ts-ignore TODO: how to get concat to merge types?
        return [].concat(folders, files)

  Bindable(undefined, self)

  return self

module.exports = DexieFS
