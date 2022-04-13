Jadelet = require "../lib/jadelet"
Observable = require "../lib/observable"

{fuzzyMatch} = require "../lib/util/index"

Template = Jadelet.exec """
  form.fuzzy-list(@submit @keydown)
    input(@placeholder @value)
    ul(tabindex=0)
      @children
"""

RowTemplate = Jadelet.exec """
  li(@click @class @dblclick data-index=@index)
    @content
"""

LoadingTemplate = Jadelet.exec """
  li Loading...
"""

keepsKeyboard = (element) ->
  element.tagName == 'INPUT' ||
  element.tagName == 'SELECT' ||
  element.tagName == 'TEXTAREA' ||
  (element.contentEditable && element.contentEditable == 'true')

module.exports = (model) ->
  {
    filter
    ItemTemplate
    items
    loading
    maxItems
    submit
    value
  } = model

  ItemTemplate ?= (x) -> x
  loading ?= Observable false
  value ?= Observable ""
  maxItems ?= Observable 100
  filter ?= (value, items) ->
    fuzzyMatch(value, items)

  activeIndex = Observable 0

  clickHandler = (e) ->
    index = parseInt e.currentTarget.dataset.index, 10
    activeIndex index

  dblclickHandler = (e) ->
    index = parseInt e.currentTarget.dataset.index, 10
    submit view.filteredItems()[index]

  view =
    activeIndex: activeIndex
    activeItem: ->
      view.filteredItems()[activeIndex()]
    loading: loading
    element: null
    children: ->
      if loading()
        return LoadingTemplate()

      view.filteredItems()
      .slice(0, maxItems())
      .map (item, index) ->
        RowTemplate
          class: ->
            "active" if index is activeIndex()
          click: clickHandler
          dblclick: dblclickHandler
          content: ItemTemplate item
          index: index

    filteredItems: ->
      filter(value(), items())

    keydown: (e) ->
      if e.key is "Enter"
        view.submit(e)
        return

      switch e.key
        when "ArrowUp"
          view.previousItem()
          e.preventDefault()

        when "ArrowDown"
          view.nextItem()
          e.preventDefault()

    placeholder: "Type to filter results"

    nextItem: ->
      n = activeIndex() + 1
      if n >= view.filteredItems().length
        n = 0
      activeIndex n

    previousItem: ->
      n = activeIndex() - 1
      if n < 0
        n = view.filteredItems().length - 1
      activeIndex  n

    submit: (e) ->
      e.preventDefault()
      submit view.activeItem()

    value: value

  activeIndex.observe (i) ->
    el = view.element.querySelectorAll(':scope > ul > li')[i]
    el?.scrollIntoView
      block: "nearest"

  view.element = Template view
  return view
