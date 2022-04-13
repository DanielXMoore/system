Bindable
========

Add event binding to objects.

    bindable = Bindable()
    handler = ->
      console.log "yo!"

    # Add handler
    bindable.on "greet", handler
    bindable.trigger "greet"
    # => "yo!" is printed to log
    
    # Remove handler
    bindable.off "greet", handler
    bindable.trigger "greet"
    # => Nothing is printed to the log
    

## Use as a mixin.

    self.include Bindable

## Add Event Listener

This will call `coolEventHandler` after `yourObject.trigger "someCustomEvent"`
is called.

    yourObject.on "someCustomEvent", coolEventHandler

## Remove Event Listener

Removes the handler coolEventHandler from the event `"someCustomEvent"` while
leaving the other events intact.

    yourObject.off "someCustomEvent", coolEventHandler

Removes all handlers attached to `"anotherCustomEvent"`

    yourObject.off "anotherCustomEvent"

## Trigger Event Listener

Calls all listeners attached to the specified event.

    # calls each event handler bound to "someCustomEvent"
    yourObject.trigger "someCustomEvent"

Additional parameters can be passed to the handlers.

    yourObject.trigger "someEvent", "hello", "anotherParameter"
