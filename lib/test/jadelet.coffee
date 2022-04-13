Observable = require "../observable"

Jadelet = require "../jadelet"
parser = require "../jadelet-parser"

sampleTemplate = """
  p
    a(@click wat=@cool @butts)
      @text
      span Cool
      @text2
"""

makeTemplate = (src) ->
  Jadelet.exec src

dispatchEvent = (element, eventName, options={}) ->
  element.dispatchEvent new Event eventName, options

###
AST is a tree of objects like:

    [tag, attributes, children]

###

describe "Jadelet Runtime", ->
  it "should render", ->
    model = {
      cool: "radical"
      butts: -> "yolo"
      text: Observable [
        "hollo world"
        " "
        "yo"
        " "
        "yo"
      ]
      text2: Observable [
        "yo wat"
      ]
    }
    
    ast = parser.parse sampleTemplate

    p = Jadelet.exec(ast)(model)
    assert.equal p.textContent, "hollo world yo yoCoolyo wat"

    model.text "yolo "
    assert.equal p.textContent, "yolo Coolyo wat"

    model.text2 "rad"
    assert.equal p.textContent, "yolo Coolrad"

  it "should compile strings", ->
    template = Jadelet.exec """
      h1 yolo
    """

    el = template()
    assert.equal el.textContent, "yolo"

  it "should return functions passed to exec", ->
    template = Jadelet.exec Jadelet.exec """
      h1 yolo
    """

    el = template()
    assert.equal el.textContent, "yolo"

describe "Attributes", ->
  it "should bind to the property with the same name", (done) ->
    template = makeTemplate """
      button(@click) Test
    """

    model =
      click: ->
        done()

    button = template(model)
    button.click()

  it "should work with multiple attributes", ->
    template = makeTemplate """
      button(before="low" @type middle="mid" @yolo after="hi") Test
    """

    model =
      type: "submit"
      yolo: "Hello"

    button = template(model)
    assert.equal button.getAttribute("type"), "submit"
    assert.equal button.getAttribute("yolo"), "Hello"

  it "shoud not be present when false or undefined", ->
    template = makeTemplate """
      button(@disabled) Test
    """

    model =
      disabled: Observable false

    button = template(model)
    assert.equal button.getAttribute("disabled"), undefined

    model.disabled true
    assert.equal button.getAttribute("disabled"), "true"

describe "Checkbox", ->
  template = makeTemplate """
    input(type='checkbox' checked=@checked)
  """

  it "should be checked", ->
    model =
      checked: true

    input = template(model)
    assert.equal input.checked, true

  it "should not be checked", ->
    model =
      checked: false

    input = template(model)
    assert.equal input.checked, false

  it "should track changes in the observable", ->
    model =
      checked: Observable false

    input = template(model)

    assert.equal input.checked, false, "Should not be checked"
    model.checked true
    assert.equal input.checked, true, "Should be checked"
    model.checked false
    assert.equal input.checked, false, "Should not be checked again"

    input.checked = true
    input.onchange()
    assert.equal model.checked(), true, "Value of observable should be checked when input changes"

    input.checked = false
    input.onchange()
    assert.equal model.checked(), false, "Value of observable should be unchecked when input changes"

describe "Classes", ->
  it "should be bound in the context of the object", ->
    template = makeTemplate """
      .duder(class=@classes)
    """

    model =
      classes: ->
        @myClass()
      myClass: ->
        "hats"

    element = template(model)
    assert element.classList.contains "hats"

  it "should handle observable arrays", ->
    template = makeTemplate """
      div(class=@classes)
    """

    model =
      classes: Observable ["a", "b"]

    element = template(model)

    assert element.classList.contains "a"
    assert element.classList.contains "b"

  it "should merge with literal classes", ->
    template = makeTemplate """
      .duder(class=@classes)
    """

    model =
      classes: Observable ["a", "b"]

    element = template(model)

    assert element.classList.contains "a"
    assert element.classList.contains "b"
    assert element.classList.contains "duder"

  it "should not write `undefined` to the class", ->
    template = makeTemplate """
      .duder(class=@undefined)
    """

    model =
      undefined: undefined

    element = template(model)

    assert !element.classList.contains("undefined")

  it "should not have the class attribute if no classes", ->
    template = makeTemplate """
      div(class=@undefined)
    """

    model =
      undefined: undefined

    element = template(model)

    assert !element.hasAttribute("class")

describe "Computed", ->
  template = makeTemplate """
    div
      h2 @name
      input(value=@first)
      input(value=@last)
  """

  it "should compute automatically with the correct scope", ->
    model =
      name: ->
        @first() + " " + @last()
      first: Observable("Mr.")
      last: Observable("Doberman")

    element = template(model)

    assert.equal element.querySelector("h2").textContent, "Mr. Doberman"

  it "should work on special bindings", ->
    template = makeTemplate """
      input(type='checkbox' checked=@checked)
    """
    model =
      checked: ->
        @name() is "Duder"
      name: Observable "Mang"

    element = template(model)

    assert.equal element.checked, false
    model.name "Duder"
    assert.equal element.checked, true

describe "Events", ->
  it "should bind click to the object context", ->
    template = makeTemplate """
      button(click=@click)
    """

    result = null

    model =
      name: Observable "Foobert"
      click: ->
        result = @name()

    button = template(model)
    assert.equal result, null
    button.click()
    assert.equal result, "Foobert"

  it "should not error on non-functions when binding events", ->
    template = makeTemplate """
      button(@mouseenter @mouseleave)
    """

    model = {}
    button = template(model)

    dispatchEvent button, "mouseenter"
    dispatchEvent button, "mouseleave"

    return

  it "doesn't late bind event functions", ->
    template = makeTemplate """
      button(@click)
    """

    model = {}
    button = template(model)
    
    called = false
    model.click = ->
      called = true

    dispatchEvent button, "click"
    assert !called

  it "should bind mouseenter and mouseleave events", ->
    template = makeTemplate """
      button(@mouseenter @mouseleave)
    """

    result = null

    model =
      mouseenter: ->
        result = 1
      mouseleave: ->
        result = 2

    button = template(model)

    assert.equal result, null
    dispatchEvent button, "mouseenter"
    assert.equal result, 1
    dispatchEvent button, "mouseleave"
    assert.equal result, 2

  it "shoud handle all touch events", ->
    template = makeTemplate """
      canvas(@touchstart @touchmove @touchend @touchcancel)
    """

    called = 0
    eventFn = ->
      called += 1

    model =
      touchcancel: eventFn
      touchstart: eventFn
      touchmove: eventFn
      touchend: eventFn

    canvas = template(model)
    assert.equal called, 0

    dispatchEvent canvas, "touchstart"
    assert.equal called, 1

    dispatchEvent canvas, "touchmove"
    assert.equal called, 2

    dispatchEvent canvas, "touchend"
    assert.equal called, 3

    dispatchEvent canvas, "touchcancel"
    assert.equal called, 4

  it "shoud handle all animation events", ->
    template = makeTemplate """
      div(@animationstart @animationiteration @animationend @transitionend)
    """

    called = 0
    eventFn = ->
      called += 1

    model =
      animationstart: eventFn
      animationend: eventFn
      animationiteration: eventFn
      transitionend: eventFn

    canvas = template(model)
    assert.equal called, 0

    dispatchEvent canvas, "animationstart"
    assert.equal called, 1

    dispatchEvent canvas, "animationiteration"
    assert.equal called, 2

    dispatchEvent canvas, "animationend"
    assert.equal called, 3

    dispatchEvent canvas, "transitionend"
    assert.equal called, 4

describe "ids", ->
  it "should work with simple cases", ->
    template = makeTemplate """
      h1#rad
    """
    element = template()

    assert.equal element.id, "rad"

  it "should be ok if empty", ->
    # TODO: Rethink this test case
    template = makeTemplate """
      h1(id)
    """
    element = template()

    assert.equal element.id, ""

  it "should use the last valid id when multiple exist", ->
    template = makeTemplate """
      h1#rad(id="cool")
    """

    element = template()
    assert.equal element.id, "cool"

  it "should update the id if it's observable", ->
    template = makeTemplate """
      h1(@id)
    """

    model =
      id: Observable "cool"

    element = template(model)
    assert.equal element.id, "cool"
    model.id "wat"
    assert.equal element.id, "wat"

  it "should update the last existing id if mixing literals and observables", ->
    template = makeTemplate """
      h1#wat(@id id=@other)
    """

    model =
      id: Observable "cool"
      other: Observable "other"

    element = template(model)
    assert.equal element.id, "other"
    model.other null
    assert.equal element.id, "cool"
    model.id null
    assert.equal element.id, "wat"

  it "should be bound in the context of the object", ->
    template = makeTemplate """
      .duder(@id)
    """

    model =
      id: ->
        @myId()
      myId: ->
        "hats"

    element = template(model)
    assert.equal element.id, "hats"

describe "input", ->
  template = makeTemplate """
    input(type="text" @value)
  """

  it "should maintain caret position", ->
    model =
      value: Observable "yolo"

    input = template(model)

    input.focus()
    input.selectionStart = 2

    assert.equal input.selectionStart, 2

    input.value = "yo2lo"
    input.selectionStart = 3

    assert.equal input.selectionStart, 3

    input.onchange()

    assert.equal input.selectionStart, 3

    # TODO: Seems reasonable... think it through
    model.value "radical"
    assert.equal input.selectionStart, 7

  it "should send updated value", ->
    model =
      value: Observable 5

    input = template(model)

    input.value = 50
    input.onchange()

    # Inputs only return strings as values
    assert.equal model.value(), "50"

describe "multiple bindings", ->
  template = makeTemplate """
    div
      input(type="text" @value)
      select(value=@value)
        @options
      hr
      input(type="range" @value min="1" @max)
      hr
      progress(@value @max)
  """
  model =
    max: 10
    value: Observable 5
    options: ->
      [1..@max].map (v) ->
        o = document.createElement "option"
        o.value = v
        o.textContent = v

        return o

  it "should be initialized to the right values", ->
    element = template(model)

    select = element.querySelector("select")

    ["text", "range"].forEach (type) ->
      assert.equal element.querySelector("input[type='#{type}']").value, 5

    assert.equal element.querySelector("progress").value, 5
    assert.equal select.value, 5

    [2, 7, 3, 8].forEach (value) ->
      model.value value

      # NOTE: This is how we're simulating an onchange event
      # TODO select element value binding
      # select.selectedIndex = value - 1
      # select.onchange()

      assert.equal select.value, value

      ["text", "range"].forEach (type) ->
        assert.equal element.querySelector("input[type='#{type}']").value, value

      assert.equal element.querySelector("progress").value, value

describe "Primitives", ->
  template = makeTemplate """
    div
      @string
      @boolean
      @number
      @array
  """

  it "should render correctly", ->
    model =
      string: "hey"
      boolean: true
      number: 5
      array: [1, true, "e"]

    element = template(model)
    assert.equal element.textContent, "heytrue51truee"

describe "Random tags", ->
  template = makeTemplate """
    div
      duder
      yolo(radical="true")
      sandwiches(type=@type)
  """
  model =
    type: Observable "ham"

  it "should be have those tags and atrtibutes", ->
    element = template(model)

    assert element.querySelector "duder"
    assert element.querySelector("yolo").getAttribute("radical")
    assert.equal element.querySelector("sandwiches").getAttribute("type"), "ham"

  it "should reflect changes in observables", ->
    element = template(model)

    assert.equal element.querySelector("sandwiches").getAttribute("type"), "ham"
    model.type "pastrami"
    assert.equal element.querySelector("sandwiches").getAttribute("type"), "pastrami"

describe "retain", ->
  it "should keep elements bound even when reused in the DOM", ->
    CanvasTemplate = makeTemplate """
      canvas(@width @height)
    """

    EditorTemplate = makeTemplate """
      editor
        @title
        @canvas
    """

    canvasModel =
      width: Observable 64
      height: Observable 64

    canvasElement = CanvasTemplate canvasModel
    Jadelet.retain canvasElement

    editorModel =
      title: Observable "yo"
      canvas: canvasElement

    editorElement = EditorTemplate editorModel

    assert.equal canvasElement.getAttribute('height'), 64

    canvasModel.height 48
    assert.equal canvasElement.getAttribute('height'), 48

    editorModel.title "lo"

    canvasModel.height 32
    assert.equal canvasElement.getAttribute('height'), 32

    Jadelet.release canvasElement

describe "Styles", ->
  it "should be bound in the context of the object", ->
    template = makeTemplate """
      duder(@style)
    """

    model =
      style: ->
        @myStyle()
      myStyle: ->
        backgroundColor: "red"

    element = template(model)
    assert.equal element.style.backgroundColor, "red"

  it "should remove styles when observables change", ->
    template = makeTemplate """
      duder(@style)
    """

    model =
      style: Observable
        backgroundColor: "red"

    element = template(model)
    assert.equal element.style.backgroundColor, "red"

    model.style
      color: "green"
    assert.equal element.style.backgroundColor, ""
    assert.equal element.style.color, "green"

  it "should merge observable arrays of style mappings", ->
    template = makeTemplate """
      div(style=@styles)
    """

    model =
      styles: Observable [{
        lineHeight: "1.5em"
        height: "30px"
        width: "40px"
      }, {
        color: "green"
        lineHeight: null
        height: undefined
        width: "50px"
      }]

    element = template(model)

    assert.equal element.style.color, "green"
    assert.equal element.style.height, "30px"
    assert.equal element.style.lineHeight, ""
    assert.equal element.style.width, "50px"

  it "should work with plain style strings", ->
    template = makeTemplate """
      div(@style)
    """

    model =
      style: """
        background-color: orange;
        color: blue;
      """

    element = template(model)

    assert.equal element.style.color, "blue"
    assert.equal element.style.backgroundColor, "orange"

  it "should mix and match plain strings and objects", ->
    template = makeTemplate """
      div(style=@rekt style=@styleString style=@styleObject)
    """

    model =
      rekt:
        height: "20px"
        color: "green"

      styleString:  """
        background-color: orange;
        color: blue;
      """

      styleObject: ->
        color: "black"
        width: "50px"

    element = template(model)

    assert.equal element.style.backgroundColor, "orange"
    assert.equal element.style.color, "black"
    assert.equal element.style.height, "" # Got crushed when writing the string style
    assert.equal element.style.width, "50px"

describe "content arrays", ->
  it "should render and update items", ->
    template = makeTemplate """
      div
        @items
    """

    model =
      count: Observable 3
      items: ->
        c = @count()
        r = []
        i = 0
        while i < c
          i++
          r.push document.createElement "p"

        return r

    element = template(model)

    assert.equal element.children.length, 3
    model.count 5
    assert.equal element.children.length, 5

  it "should keep them in order and not re-render excessively", ->
    template = makeTemplate """
      div
        @items
        @otherItems
        hr
    """

    model =
      count: Observable 3
      otherCount: Observable 2
      items: ->
        c = @count()
        r = []
        i = 0
        while i < c
          i++
          r.push document.createElement "p"

        return r
      otherItems: ->
        c = @otherCount()
        r = []
        i = 0
        while i < c
          i++
          r.push document.createElement "a"

        return r

    element = template(model)

    assert.equal element.querySelectorAll('p').length, 3
    assert.equal element.querySelectorAll('a').length, 2
    firstA = element.children[3]

    model.count 0

    assert.equal element.querySelectorAll('p').length, 0
    assert.equal element.querySelectorAll('a').length, 2

    # Node is maintained
    assert.equal firstA, element.children[0]

    model.count 7

    assert.equal element.querySelectorAll('p').length, 7
    assert.equal element.querySelectorAll('a').length, 2

    # Node is maintained
    assert.equal firstA, element.children[7]

    model.otherCount 1
    # Node is re-created when dependency changes in this circumstance
    # up to the model to cache
    assert.notEqual firstA, element.children[7]

describe "subrender", ->
  describe "rendering simple text", ->
    template = makeTemplate """
      span.count @count
    """

    it "should render numbers as strings", ->
      model =
        count: 5

      element = template(model)
      assert.equal element.textContent, "5"

    it "should update when observable changes", ->
      model =
        count: Observable 5

      element = template(model)
      assert.equal element.textContent, "5"
      model.count 2
      assert.equal element.textContent, "2"

  describe "with root node", ->
    template = makeTemplate """
      div
        @generateItem
    """

    it "should render elements in-line", ->
      model =
        generateItem: ->
          document.createElement("li")

      element = template(model)
      assert element.querySelector("li")

    it "should render lists of nodes", ->
      model =
        generateItem: ->
          [
            document.createElement("li")
            document.createElement("li")
            document.createElement("p")
          ]

      element = template(model)
      assert element.querySelectorAll("li").length, 2
      assert element.querySelectorAll("p").length, 1

    it "should work with a node with children", ->
      model =
        generateItem: ->
          div = document.createElement "div"

          div.innerHTML = "<p>Yo</p><ol><li>Yolo</li><li>Broheim</li></ol>"

          div

      element = template(model)

      assert element.querySelectorAll("li").length, 2
      assert element.querySelectorAll("p").length, 1
      assert element.querySelectorAll("ol").length, 1

    it "should work with observables", ->
      model =
        name: Observable "wat"
        generateItem: ->
          item = document.createElement("li")

          item.textContent = @name()

          item

      element = template(model)

      assert.equal element.querySelectorAll("li").length, 1
      assert.equal element.querySelector("li").textContent, "wat"
      model.name "yo"
      assert.equal element.querySelector("li").textContent, "yo"

  describe "rendering subtemplates", ->
    describe "mixing and matching", ->
      subtemplate = makeTemplate """
        span Hello
      """
      template = makeTemplate """
        div
          a Radical
          |
          @subtemplate
          |
          @observable
          @nullable
      """

      it "shouldn't lose any nodes", ->
        model =
          observable: Observable "wat"
          subtemplate: subtemplate
          nullable: null

        element = template(model)
        assert.equal element.textContent, "Radical\nHello\nwat"
        model.observable "duder"
        assert.equal element.textContent, "Radical\nHello\nduder"

    describe "mapping array to subtemplates", ->
      template = makeTemplate """
        table
          @rows
      """

      it "should render subtemplates", ->
        model =
          rows: -> [
            {text: "Wat"}
            {text: "is"}
            {text: "up"}
          ].map @subtemplate
          subtemplate: makeTemplate """
            tr
              td @text
          """

        element = template(model)
        assert.equal element.querySelectorAll("tr").length, 3

      it "should maintain observables in subtemplates", ->
        data = Observable [
          {text: Observable "Wat"}
          {text: Observable "is"}
          {text: Observable "up"}
        ]
        model =
          rows: ->
            data.map @subtemplate
          subtemplate: makeTemplate """
            tr
              td @text
          """

        element = template(model)
        assert.equal element.querySelectorAll("tr").length, 3
        assert.equal element.querySelector("td").textContent, "Wat"

        data()[0].text "yo"

        assert.equal element.querySelector("td").textContent, "yo"

        data.push text: Observable("dude")

        assert.equal element.querySelectorAll("tr").length, 4
        assert.equal element.querySelector("td").textContent, "yo"

        data()[0].text "holla"
        assert.equal element.querySelector("td").textContent, "holla"

describe "element properties", ->
  it "should use the element property of objects rendered", ->
    src = """
      ul
        @a
        @b
    """
    template = makeTemplate src

    element = template
      a:
        element: document.createElement 'a'
      b:
        element: document.createElement 'b'

    assert element.querySelector("a")
    assert element.querySelector("b")
    assert !element.querySelector("c")

# This test captures a bug where caching elements and appending to a list
# caused the element Observables to be disposed because they were released
# before being re-added and the observers were cleaned up.
describe "cached retains", ->
  it "should not release elements that are consistent render to render", ->
    Container = makeTemplate """
      div
        @elements
    """
    Item = makeTemplate """
      input(@value)
    """

    ItemView = (i) ->
      view = cache.get(i)
      if view
        return view

      item =
        value: Observable(i)

      view =
        item: item
        element: Item item

      cache.set(i, view)
      return view

    # Cache of item Views
    cache = new Map
    itemViews = [0...3].map ItemView

    containerView =
      elements: Observable itemViews

    element = Container containerView

    assert.equal element.children.length, 3
    containerView.elements()[0].item.value 100
    assert.equal element.children[0].value, 100

    containerView.elements.push ItemView 3
    assert.equal element.children.length, 4
    containerView.elements()[0].item.value 200
    # This will fail to set if we've removed the observers
    assert.equal element.children[0].value, 200

describe "text", ->
  it "should preserve line breaks", ->
    src = """
      p
        | hello I am a cool paragraph
        | with lots of text and stuff
        | ain't it rad?
    """
    template = makeTemplate src

    element = template()
  
    assert.equal element.textContent, """
      hello I am a cool paragraph
      with lots of text and stuff
      ain't it rad?\n
    """

describe "svg", ->
  it "should render svg", ->
    src = """
      section
        h2 svg test
        svg(width=100 height=100)
          circle(cx=80 cy=80 r=30 fill="red")
        p awesome
    """

    template = makeTemplate src
    element = template()

    assert.equal element.querySelector('svg').namespaceURI, "http://www.w3.org/2000/svg"

describe "indentation", ->
  it "should work with somewhat flexible indentation for ease of use with
    template strings in js", ->
      indentedTemplate1 = """
        p
                a(@click) Cool
      """

      indentedTemplate2 = indentedTemplate1.replace(/^/, "      ")

      T1 = makeTemplate indentedTemplate1
      T2 = makeTemplate indentedTemplate2

      el = T1()
      assert.equal el.querySelector('a').textContent, "Cool"

      el = T2()
      assert.equal el.querySelector('a').textContent, "Cool"

describe "weird cases", ->
  it.skip "should handle weird templates", ->
    makeTemplate '''
      .palette
        .primary.color
          - style = ->
            - c = editor.activeColor()
            - "background-color: #{c}"
          input(type="color" value=@activeColor style=@activeColorStyle)

        @swatchElements
        @opacityElement
    '''
