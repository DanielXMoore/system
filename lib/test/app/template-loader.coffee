require "../../../setup"
TemplateLoader = require "../../app/template-loader"

# TODO
describe.skip "template loader", ->
  it "should load templates", ->
    tl = TemplateLoader(PACKAGE)

    assert tl.Progress
