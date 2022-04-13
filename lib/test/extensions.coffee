require "../extensions"

describe "extensions", ->
  describe "Blob", ->
    it "should have promise convenience methods", ->
      b = new Blob(["{}"])

      b.arrayBuffer()
      .then ->
        b.json()
      .then ->
        b.text()
      .then ->
        b.dataURL()

    it "should have download method", ->
      assert Blob::download

  it "should extend native APIs with extensions", ->
    assert FileList::forEach
    assert HTMLCollection::forEach

    assert Image.fromBlob

    assert JSON.toBlob
