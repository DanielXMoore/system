WindowTemplate = require "../templates/window"

{elementView} = require "../util"

# We need an invisible full screen overlay to keep iframes from eating our
# mousemove events
frameGuard = document.createElement "frame-guard"
document.body.appendChild frameGuard

topIndex = 0
raiseToTop = (view) ->
  return unless typeof view.zIndex is 'function'
  zIndex = view.zIndex()
  return if zIndex is topIndex
  topIndex += 1

  view.zIndex(topIndex)

# Drag Handling
activeDrag = null
dragStart = null
document.addEventListener "mousedown", (e) ->
  {target} = e

  view = elementView target
  if view
    # TODO: only raise widows?
    raiseToTop view
    view.savePosition?()

  if target.tagName is "TITLE-BAR"
    dragStart = e
    activeDrag = view

document.addEventListener "mousemove", (e) ->
  if activeDrag
    frameGuard.classList.add("active")
    {clientX:prevX, clientY:prevY} = dragStart
    {clientX:x, clientY:y} = e
    dragStart = e

    if activeDrag.maximized()
      activeDrag.restore()
      activeDrag.x x - activeDrag.width() / 2
      activeDrag.y y - 30

    dx = x - prevX
    dy = y - prevY

    activeDrag.x activeDrag.x() + dx
    activeDrag.y activeDrag.y() + dy

    # Hot Edges / Corners
    leftEdge = x <= 10
    rightEdge = x >= document.documentElement.getBoundingClientRect().width - 10
    hotX = leftEdge or rightEdge

    topEdge = y <= 10
    bottomEdge = y >= document.documentElement.getBoundingClientRect().height - 10
    hotY = topEdge or bottomEdge

    if hotX or hotY
      xPos = "0%"
      yPos = "0%"
      hotWidth = "50%"
      hotHeight = "50%"

      if !hotX
        hotWidth = "100%"

      if !hotY
        hotHeight = "100%"

      if bottomEdge
        yPos = "50%"

      if rightEdge
        xPos = "50%"

      activeDrag.saveSize()
      activeDrag.maximized(true)
      activeDrag.x(xPos)
      activeDrag.y(yPos)
      activeDrag.width(hotWidth)
      activeDrag.height(hotHeight)

# Resize Handling
activeResize = null
resizeStart = null
resizeInitial = null
document.addEventListener "mousedown", (e) ->
  {target} = e

  if target.tagName is "RESIZE"
    frameGuard.classList.add("active")
    resizeStart = e
    activeResize = target
    {width, height, x, y} = elementView activeResize
    resizeInitial =
      width: width()
      height: height()
      x: x()
      y: y()

document.addEventListener "mousemove", (e) ->
  if activeResize
    {clientX:startX, clientY:startY} = resizeStart
    {clientX:x, clientY:y} = e

    dx = x - startX
    dy = y - startY

    width = resizeInitial.width
    height = resizeInitial.height

    if activeResize.classList.contains("e")
      width += dx

    if activeResize.classList.contains("w")
      width -= dx

    if activeResize.classList.contains("s")
      height += dy

    if activeResize.classList.contains("n")
      height -= dy

    width = Math.max(width, 200)
    height = Math.max(height, 50)

    actualDeltaX = width - resizeInitial.width
    actualDeltaY = height - resizeInitial.height

    view = elementView activeResize
    if activeResize.classList.contains("n")
      view.y resizeInitial.y - actualDeltaY

    if activeResize.classList.contains("w")
      view.x resizeInitial.x - actualDeltaX

    view.width width
    view.height height

    view.trigger "resize"

document.addEventListener "mouseup", ->
  activeDrag = null
  activeResize = null
  frameGuard.classList.remove("active")

Bindable = require "../lib/bindable"
Observable = require "../lib/observable"

module.exports = (params) ->
  self = Bindable()

  x = Observable params.x ? 50
  y = Observable params.y ? 50
  width = Observable params.width ? 400
  height = Observable params.height ? 300
  title = Observable params.title ? "Untitled"
  minimized = Observable false
  maximized = Observable false
  prevWidth = Observable null
  prevHeight = Observable null
  prevX = Observable null
  prevY = Observable null
  iconURL = Observable params.iconURL or "data:image/x-icon;base64,AAABAAIAICAQAAEABADoAgAAJgAAABAQEAABAAQAKAEAAA4DAAAoAAAAIAAAAEAAAAABAAQAAAAAAIACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAvwAAvwAAAL+/AL8AAAC/AL8Av78AAMDAwACAgIAAAAD/AAD/AAAA//8A/wAAAP8A/wD//wAA////AAAAAAAAAAAAAAAAAAAAAAAACHd3d3d3d3d3d3d3dwAAAAj///////////////cAAAAI///////////////3AAAACP///////3d///d39wAAAAj/zMzM//mZ//+Zn/cAAAAI////////l///+X/3AAAACP/MzMzM//l3d3l/9wAAAAj/////////mZmZf/cAAAAI/8zMzMzM//l/+X/3AAAACP//////////l/l/9wAAAAj/zMzMzMzM//l5f/cAAAAI////////////mX/3AAAACP/MzMzMzMzM//n/9wAAAAj///////////////cAAAAI/8zMzMzMzMzMzP/3AAAACP//////////////9wAAAAj/zMzMzMzMzMzM//cAAAAI///////////////3AAAACP8AAAAA/8zMzMz/9wAAAAj/iZD/8P////////cAAAAI/4AAAAD/zMzMzP/3AAAACP+P8Luw////////9wAAAAj/gAC7sP/MzMzM//cAAAAI/4/wu7D////////3AAAACP+P8Luw/////4AAAAAAAAj/j/AAAP////+P94AAAAAI/4/wzMD/////j3gAAAAACP+IiIiA/////4eAAAAAAAj///////////+IAAAAAAAI////////////gAAAAAAACIiIiIiIiIiIiIAAAAAA4AAAB+AAAAfgAAAH4AAAB+AAAAfgAAAH4AAAB+AAAAfgAAAH4AAAB+AAAAfgAAAH4AAAB+AAAAfgAAAH4AAAB+AAAAfgAAAH4AAAB+AAAAfgAAAH4AAAB+AAAAfgAAAH4AAAB+AAAAfgAAAP4AAAH+AAAD/gAAB/4AAA/+AAAf8oAAAAEAAAACAAAAABAAQAAAAAAMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAvwAAvwAAAL+/AL8AAAC/AL8Av78AAMDAwACAgIAAAAD/AAD/AAAA//8A/wAAAP8A/wD//wAA////AAAAAAAAAAAACHd3d3d3cAAI//////9wAAj8z5//n3AACP//+ZmfcAAI/MzPn59wAAj////5n3AACPzMzM+fcAAI//////9wAAjwAPzMz3AACPmY////cAAI/Pj8zM9wAAj8+P//AAAACPiI//9/gAAI/////3gAAAiIiIiIgAAAgAMAAIADAACAAwAAgAMAAIADAACAAwAAgAMAAIADAACAAwAAgAMAAIADAACAAwAAgAMAAIAHAACADwAAgB8AAA=="
  iconEmoji = Observable params.iconEmoji or null

  iconStyle = Observable ->
    if iconEmoji()
      """
        width: 18px;
      """
    else
      """
        background-image: url(#{iconURL()});
        width: 18px;
      """

  topIndex += 1
  zIndex = Observable params.zIndex ? topIndex

  element = WindowTemplate
    iconStyle: iconStyle
    iconEmoji: iconEmoji
    title: title
    menuBar: params.menuBar
    content: params.content
    class: ->
      [
        "minimized" if minimized()
        "maximized" if maximized()
      ]
    close: ->
      self.close()
    minimize: ->
      self.minimize()
    maximize: ->
      self.maximize()
    restore: ->
      self.restore()

  styleBind(y, element, "top", "px")
  styleBind(x, element, "left", "px")
  styleBind(height, element, "height", "px")
  styleBind(width, element, "width", "px")
  styleBind(zIndex, element, "zIndex")

  restore = ->
    if prevX()?
      x prevX()

    if prevY()?
      y prevY()

    width prevWidth()
    height prevHeight()

    minimized false
    maximized false

    self.trigger "resize"

  Object.assign self,
    element: element
    iconEmoji: iconEmoji
    iconURL: iconURL
    title: title
    x: x
    y: y
    width: width
    height: height
    zIndex: zIndex
    close: ->
      # TODO: Allow prompt to cancel
      # Maybe we count on people to override this method if they want
      element.remove()
      self.trigger "close"

    savePosition: ->
      if typeof x() is 'number'
        prevX x()
      if typeof y() is 'number'
        prevY y()

    saveSize: ->
      prevWidth width()
      prevHeight height()

    maximized: maximized
    maximize: ->
      maximized.toggle()

      if maximized()
        self.savePosition()
        self.saveSize()

        width null
        height null
        x 0
        y 0

        self.trigger "resize"
        self.trigger "maximize"
      else
        restore()

    minimized: minimized
    minimize: ->
      minimized.toggle()

      if minimized()
        self.savePosition()
        self.saveSize()

        width null
        height null

        self.trigger "resize"
        self.trigger "minimize"
      else
        restore()

    restore: ->
      restore()

    raiseToTop: ->
      raiseToTop self

  element.view = self

  return self

styleBind = (observable, element, attr, suffix="") ->
  update = (newValue) ->

    if typeof newValue is "string"
      element.style[attr] = newValue
    else if newValue? and (newValue = parseInt newValue)?
      element.style[attr] = "#{newValue}#{suffix}"
    else
      element.style[attr] = null

  observable.observe update

  update(observable())
