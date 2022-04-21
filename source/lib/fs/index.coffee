MountFS = require "./mount"
DexieFS = require "./dexie"
PkgFS = require "./pkg"
S3FS = require "./s3"

module.exports = Object.assign
  Dexie: DexieFS
  Mount: MountFS
  Package: PkgFS
  S3: S3FS
, require "./util"
