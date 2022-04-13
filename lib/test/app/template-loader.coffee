require "/setup"
TemplateLoader = require "/lib/app/template-loader"

describe "template loader", ->
  it "should load templates", ->
    tl = TemplateLoader(PACKAGE)

    assert tl.Progress
