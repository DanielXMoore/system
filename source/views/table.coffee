{empty} = require "../util"

TableTemplate = require "../templates/table"

# Focus same cell in next row
advanceRow = (path, prev) ->
  [td] = path.filter (element) ->
    element.tagName is "TD"
  return unless td

  tr = td.parentElement
  cellIndex = Array::indexOf.call(tr.children, td)
  if prev
    nextRowElement = tr.previousSibling
  else
    nextRowElement = tr.nextSibling

  if nextRowElement
    input = nextRowElement.children[cellIndex].querySelector('input')
    input?.focus()

# The table view takes source data and a constructor that returns a row element
# for each source datum

# The view will have the ability to filter/sort the data.

TableView = ({data, headers, RowElement}) ->
  headers ?= Object.keys data[0]

  containerElement = TableTemplate
    headerElements: headers.map (header) ->
      th = document.createElement 'th'
      th.textContent = header
      return th
    keydown: (event) ->
      {key, path} = event
      switch key
        when "Enter", "ArrowDown"
          event.preventDefault()
          advanceRow path
        when "ArrowUp"
          event.preventDefault()
          advanceRow path, true
        # TODO: Left and Right
        # Left and Right are trickier because you may want to navigate within a text input
        # ... actually up and down get trickier too if we imagine text areas or
        # even fancier inputs that may have their own controls...

  tableBody = containerElement.querySelector('tbody')

  filterFn = (datum) ->
    true

  filterAndSort = (data, filterFn, sortFn) ->
    filterFn ?= -> true
    filteredData = data.filter(filterFn)

    if sortFn
      filteredData.sort(sortFn)
    else
      filteredData

  rowElements = ->
    filterAndSort(data, filterFn, null).map RowElement

  update = ->
    empty tableBody
    rowElements().forEach (element) ->
      tableBody.appendChild element

  update()

  element: containerElement
  render: update

module.exports = TableView
