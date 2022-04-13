Core = require "/lib/exp/core-state"

describe 'Core', ->
  # Association Testing model
  Person = (self) ->
    person = Core self

    person.attrObservable(
      'firstName'
      'lastName'
      'suffix'
    )

    person.fullName = ->
      "#{@firstName()} #{@lastName()} #{@suffix()}"

    return person

  it "#extend", ->
    o = Core()

    o.extend
      test: "jawsome"

    assert.equal o.test, "jawsome"

  it "#include", ->
    o = Core
      __state:
        test: "my_val"

    M = (self) ->
      self.extend
        test2: "cool"
        test: ->
          self.__state.test

    ret = o.include M

    assert.equal ret, o, "Should return self"

    assert.equal o.test(), "my_val"
    assert.equal o.test2, "cool"

  it "#include multiple", ->
    o = Core
      test: "my_val"

    M = (self) ->
      self.extend
        test2: "cool"

    M2 = (self) ->
      self.extend
        test2: "coolio"

    o.include M, M2

    assert.equal o.test2, "coolio"

  describe "#attrData", ->
    pointProto =
      add: ({x, y}) ->
        @x += x
        @y += y

    Point = ({x, y}) ->
      Object.create pointProto,
        x:
          value: x
        y:
          value: y

    it "should expose a property mapping to the instance data", ->
      model = Core
        __state:
          position:
            x: 5
            y: 5

      model.attrData "position", Point

      assert model.position.add

      model.position.x = 12
      assert.equal model.position.x, model.__state.position.x

      model.position =
        x: 9
        y: 6

      assert.equal model.position.y, 6
      assert.equal model.__state.position.x, 9

  describe "#attrObservable", ->
    it 'should allow for observing of attributes', ->
      model = Core
        name: "Duder"

      model.attrObservable "name"

      model.name("Dudeman")

      assert.equal model.name(), "Dudeman"

    it 'should bind properties to observable attributes', ->
      model = Core
        name: "Duder"

      model.attrObservable "name"

      model.name("Dudeman")

      assert.equal model.name(), "Dudeman"
      assert.equal model.name(), model.__state.name

  describe "#attrModel", ->
    it "should be a model instance", ->
      model = Core
        __state:
          person:
            firstName: "Duder"
            lastName: "Mannington"
            suffix: "Jr."

      model.attrModel("person", Person)

      assert.equal model.person().fullName(), "Duder Mannington Jr."

    it "should allow setting the associated model", ->
      model = Core
        __state:
          person:
            firstName: "Duder"
            lastName: "Mannington"
            suffix: "Jr."

      model.attrModel("person", Person)

      otherPerson = Person
        __state:
          firstName: "Mr."
          lastName: "Man"

      model.person(otherPerson)

      assert.equal model.person().firstName(), "Mr."

    it "shouldn't update the instance properties after it's been replaced", ->
      model = Core
        __state:
          person:
            firstName: "Duder"
            lastName: "Mannington"
            suffix: "Jr."

      model.attrModel("person", Person)

      duder = model.person()

      otherPerson = Person
        __state:
          firstName: "Mr."
          lastName: "Man"

      model.person(otherPerson)

      duder.firstName("Joe")

      assert.equal duder.__state.firstName, "Joe"
      assert.equal model.__state.person.firstName, "Mr."

  describe "#attrModels", ->
    it "should have an array of model instances", ->
      model = Core
        __state:
          people: [{
            firstName: "Duder"
            lastName: "Mannington"
            suffix: "Jr."
          }, {
            firstName: "Mr."
            lastName: "Mannington"
            suffix: "Sr."
          }]

      model.attrModels("people", Person)

      assert.equal model.people()[0].fullName(), "Duder Mannington Jr."

    it "should track pushes", ->
      model = Core
        __state:
          people: [{
            firstName: "Duder"
            lastName: "Mannington"
            suffix: "Jr."
          }, {
            firstName: "Mr."
            lastName: "Mannington"
            suffix: "Sr."
          }]

      model.attrModels("people", Person)

      model.people.push Person
        firstName: "JoJo"
        lastName: "Loco"

      assert.equal model.people().length, 3
      assert.equal model.__state.people.length, 3

    it "should track pops", ->
      model = Core
        __state:
          people: [{
            firstName: "Duder"
            lastName: "Mannington"
            suffix: "Jr."
          }, {
            firstName: "Mr."
            lastName: "Mannington"
            suffix: "Sr."
          }]

      model.attrModels("people", Person)

      model.people.pop()

      assert.equal model.people().length, 1
      assert.equal model.__state.people.length, 1

  describe "#delegate", ->
    it "should delegate to another method", ->
      model = Core
        __state:
          position:
            x: 1
            y: 2
            z: 3
        position: ->
          model.__state.position

      model.delegate "x", "y", "z", to: "position"

      assert.equal model.x, 1
      assert.equal model.y, 2
      assert.equal model.z, 3

      model.x = 5

      assert.equal model.position().x, 5
      assert.equal model.__state.position.x, 5

    it "should delegate to another property", ->
      model = Core
        __state:
          position:
            x: 1
            y: 2
            z: 3

      model.position = model.__state.position

      model.delegate "x", "y", "z", to: "position"

      assert.equal model.x, 1
      assert.equal model.y, 2
      assert.equal model.z, 3

      model.x = 5

      assert.equal model.position.x, 5
      assert.equal model.__state.position.x, 5

    it "should delegate to methods just fine", ->
      model = Core
        __state:
          size:
            width: 10
            height: 20

      model.attrData "size", ({width, height}) ->
        width: -> width
        height: -> height

      model.delegate "width", "height", to: "size"

      assert.equal model.width(), 10
      assert.equal model.height(), 20

  describe "#toJSON", ->
    it "should return an object appropriate for JSON serialization", ->
      model = Core
        __state:
          test: true

      assert model.toJSON().test

  describe "#observeAll", ->
    it "should observe all attributes of a simple model"
    ->  # TODO
      model = Core
        test: true
        yolo: "4life"

      model.observeAll()

      assert model.test()
      assert.equal model.yolo(), "4life"

    it "should camel case underscored names"

  describe ".defaults", ->
    it "should expose defaults method", ->
      assert Core.defaults

  describe ".extend", ->
    it "should expose extend method", ->
      assert Core.extend
