S3FS = require "../../fs/s3"

# mock bucket interface
bucket =
  getObject: (data, cb) ->
    cb(null)
  headObject: (data, cb) ->
    cb(null, {
      ContentType: "text/plain"
      LastModified: "2021-05-05T01:00:46.000Z"
    })
  putObject: (data, cb) ->
    cb(null)
  listObjects: (data, cb) ->
    cb(null, {
      CommonPrefixes: []
      Contents: [{
        Key: "yo"
        Size: 3
      }]
    })

describe "S3FS", ->
  it "Should cache the proper date when writing then listing", ->
    id = "wat"

    refreshCredentials = ->

    fs = S3FS(id, bucket, refreshCredentials)

    fs.write "yo", new Blob ['hey']
    .then ->
      fs.list()
    .then (entries) ->
      assert.notEqual entries[0].updatedAt.toString(), "Invalid Date"
