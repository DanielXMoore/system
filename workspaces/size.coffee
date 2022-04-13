fmt = (size) ->
  size.toString().padStart(10)

total = 0

items = Object.keys(PACKAGE.source).map (name) ->
  [name, PACKAGE.source[name].content.length]
.sort (a, b) ->
  b[1] - a[1]
.map ([name, size]) ->
  total += size

  fmt(size) + " " + name
.join("\n")

pre = document.createElement "pre"
pre.textContent = """
#{items}
------------------------------
#{fmt(total)} Source Total

#{fmt(JSON.stringify(PACKAGE).length)} Package Total
"""
pre.style.overflow = "auto"

document.body.appendChild pre
