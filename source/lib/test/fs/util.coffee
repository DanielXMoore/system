{
  absolutizePath
  baseDirectory
  extensionFor
  isRelativePath
  textMediaType
  normalizePath
  # normalizePath2:normalizePath
  withoutExtension
  withoutAllExtensions
} = require "../../fs/index"

describe "fs", ->
  describe "util", ->
    it "should absolutize paths", ->
      assert.equal absolutizePath("/Home/", "app.config"), "/Home/app.config"

      assert.equal absolutizePath("/Home/", "something/../app.config"), "/Home/app.config"
      assert.equal absolutizePath("/Home/", "/something/../app.config"), "/Home/app.config"

      assert.equal absolutizePath("/Home//", "///./app.config"), "/Home/app.config"
      assert.equal absolutizePath("/Home/./", "///./app.config"), "/Home/app.config"

    it "should error when escaping base dir", ->
      assert.throws ->
        absolutizePath("/Home/", "../app.config")

    it "should normalize paths", ->
      assert.equal normalizePath("///./app.config"), "/app.config"
      assert.equal normalizePath("/yolo/.././/./app.config"), "/app.config"
      assert.equal normalizePath("yolo/rad/..//./app.config"), "yolo/app.config"

      assert.equal normalizePath("/public/danielx.net/.."), "/public/"
      assert.equal normalizePath("/public/danielx.net/."), "/public/danielx.net/"

      assert.equal normalizePath("/public/..weird/danielx.net/"), "/public/..weird/danielx.net/"

    it "should normalize strage cases", ->
      assert.equal normalizePath("./"), "./"
      assert.equal normalizePath("./cool"), "./cool"

    it.skip "should throw an error when there is no parent directory", ->
      assert.throws ->
        normalizePath "/../danielx.net/"
      assert.throws ->
        normalizePath "./.."
      assert.throws ->
        normalizePath "/./.."

    it "should know relative paths", ->
      assert.equal isRelativePath("../yo.txt"), true
      assert.equal isRelativePath("./yo.md"), true

      assert.equal isRelativePath("/Home/yo"), false

    describe "baseDirectory", ->
      it "should resolve base directories", ->
        # A directory is its own base directory
        assert.equal baseDirectory("/Home/"), "/Home/"
        # The directory that contains a file is that file's base directory
        assert.equal baseDirectory("/Home/cool.gif"), "/Home/"
        # A non-root path can be a base directory
        assert.equal baseDirectory("folder/sub/cool.gif"), "folder/sub/"

      it "should have base directory undefined if no folder", ->
        assert.equal baseDirectory("just-a-file.js"), undefined

    describe "extensionFor", ->
      it "should give extensios", ->
        assert.equal extensionFor("home/rad.js"), "js"
        assert.equal extensionFor("home/rad.js.md"), "md"

      it "should handle directories with a dot", ->
        assert.equal extensionFor("home.app/md"), ""
        assert.equal extensionFor("home.app/cool.md"), "md"

    describe "textMediaType", ->
      it "should return the proper mime types", ->
        assert.equal textMediaType("cool.html"), "text/html; charset=utf-8"
        assert.equal textMediaType("sick.js"), "text/javascript; charset=utf-8"
        assert.equal textMediaType("noice.json"), "application/json; charset=utf-8"
        assert.equal textMediaType("rad.txt"), "text/plain; charset=utf-8"
        assert.equal textMediaType("lit.md"), "text/markdown; charset=utf-8"
        assert.equal textMediaType("yo.coffee"), "text/plain; charset=utf-8"
        assert.equal textMediaType("style.styl"), "text/plain; charset=utf-8"
        # Any unrecognized type is text/plain
        assert.equal textMediaType("heyy.webm"), "text/plain; charset=utf-8"

    describe "withoutExtension", ->
      it "should remove extensions", ->
        assert.equal withoutExtension("cool/file.ab.c"), "cool/file.ab"
        assert.equal withoutExtension("but.why/file.ab.c"), "but.why/file.ab"
        assert.equal withoutExtension("but.why/file"), "but.why/file"

    describe "withoutAllExtensions", ->
      it "should remove extensions", ->
        assert.equal withoutAllExtensions("cool/file.ab.c"), "cool/file"
        assert.equal withoutAllExtensions("but.why/file.ab.c"), "but.why/file"
        assert.equal withoutExtension("but.why/file"), "but.why/file"
