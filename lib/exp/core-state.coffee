###
NOTE: This is experimenting with passing a single `self` reference rather than
`I`, `self` as parameters. I don't think it is better, but it was worth
comparing.

Core
====

`Core` provides helper methods to compose nested data models. It handles
data persistence and state binding. It provides common helpers and extensions
to expand an object with modules.

By providing a common way to bind state and compose data we can use Core as a
common building block for many types of objects.

###

Observable = require "../observable"

module.exports = Model = (self={}) ->
  defaults self,
    __state: {}

  extend self,
    ###
    Extends this object with methods from the passed in object. A shortcut for Object.extend(self, methods)
    
    >     I =
    >       x: 30
    >       y: 40
    >       maxSpeed: 5
    >
    >     # we are using extend to give player
    >     # additional methods that Model doesn't have
    >     player = Model(I).extend
    >       increaseSpeed: ->
    >         I.maxSpeed += 1
    >
    >     player.increaseSpeed()
    
    ###
    extend: (objects...) ->
      extend self, objects...

    ###
    Includes a module in this object. A module is a constructor that takes one 
    parameter `self`. It extends the object with any additional behavior.
    
    >     myObject = Model()
    >     myObject.include(Bindable)
    
    >     # now you can bind handlers to functions
    >     myObject.bind "someEvent", ->
    >       alert("wow. that was easy.")
    ###
    include: (modules...) ->
      for Module in modules
        Module(self)

      return self

    ###
    Bind a data model getter/setter to an attribute. The data model is bound directly to
    the attribute and must be directly convertible to and from JSON.
    ###
    attrData: (name, DataModel) ->
      self.__state[name] = DataModel(self.__state[name])

      Object.defineProperty self, name,
        get: ->
          self.__state[name]
        set: (value) ->
          self.__state[name] = DataModel(value)

    ###
    Observe any number of attributes as observables. For each attribute name passed in we expose a public getter/setter method and listen to changes when the value is set.
    ###
    attrObservable: (names...) ->
      names.forEach (name) ->
        self[name] = Observable(self.__state[name])

        self[name].observe (newValue) ->
          self.__state[name] = newValue

      return self

    ###
    Observe an attribute as a model. Treats the attribute given as an Observable
    model instance exposing a getter/setter method of the same name. The Model
    constructor must be passed explicitly.
    ###
    attrModel: (name, Model) ->
      model = Model
        __state: self.__state[name]

      self[name] = Observable(model)

      self[name].observe (newValue) ->
        self.__state[name] = newValue.__state

      return self

    ###
    Observe an attribute as an array of sub-models. This is the same as `attrModel`
    except the attribute is expected to be an array of models rather than a single one.
    ###
    attrModels: (name, Model) ->
      models = (self.__state[name] or []).map (x) ->
        Model
          __state: x

      self[name] = Observable(models)

      self[name].observe (newValue) ->
        self.__state[name] = newValue.map (instance) ->
          instance.__state

      return self

    ###
    Delegate methods to another target. Makes it easier to compose rather than extend.
    ###
    delegate: (names..., {to}) ->
      names.forEach (name) ->
        Object.defineProperty self, name,
          get: ->
            receiver = getValue self, to
            receiver[name]
          set: (value) ->
            receiver = getValue self, to
            setValue receiver, name, value

    ###
    The JSON representation is kept up to date via the observable properites and resides in `I`.
    ###
    toJSON: ->
      self.__state

  return self

isFn = (x) ->
  typeof x is 'function'

getValue = (receiver, property) ->
  if isFn receiver[property]
    receiver[property]()
  else
    receiver[property]

setValue = (receiver, property, value) ->
  target = receiver[property]

  if isFn target
    target.call(receiver, value)
  else
    receiver[property] = value

defaults = (target, objects...) ->
  for object in objects
    for name of object
      unless target.hasOwnProperty(name)
        target[name] = object[name]

  return target

extend = Object.assign

Object.assign Model, {Observable, defaults, extend}
