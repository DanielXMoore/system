DexieFS = require "/lib/fs/dexie"

# TODO: Can't test IndexedDB in this sandbox
describe.skip "DexieFS", ->
  it "Should use indexeddb as a file system", ->
    dfs = DexieFS("test")

    dfs.write "/test.txt", new Blob ["heyy"]
    .then ->
      dfs.read("/test.txt")
