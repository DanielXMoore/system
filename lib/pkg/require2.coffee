# Testing a more compact version of require, also looking into packaging as
# js objects with functions and not source text inside json. We'll need both,
# json for loading packages as data from URLs, but we don't want to pay the
# extra character escaping when loading directly on a page.

# Goal is smaller package outputs, especially when embedded in script tags
# handle requiring `function(){}` properties in distribution.

create = (create) ->
  fileSeparator = '/'
  global = self
  defaultEntryPoint = "main"
  circularGuard = {}

  rootModule =
    path: ""
  
  loadPath = (parentModule, pkg, path) ->
    if startsWith(path, '/')
      localPath = []
    else
      localPath = parentModule.path.split(fileSeparator)
  
    normalizedPath = normalizePath(path, localPath)
  
    cache = cacheFor(pkg)
  
    if module = cache[normalizedPath]
      if module is circularGuard
        throw "Circular dependency detected when requiring #{normalizedPath}"
    else
      cache[normalizedPath] = circularGuard
  
      try
        cache[normalizedPath] = module = loadModule(pkg, normalizedPath)
      finally
        delete cache[normalizedPath] if cache[normalizedPath] is circularGuard
  
    return module.exports
  
  normalizePath = (path, base=[]) ->
    base = base.concat path.split(fileSeparator)
    result = []
  
    while base.length
      switch piece = base.shift()
        when ".."
          result.pop()
        when "", "."
          # Skip
        else
          result.push(piece)
  
    return result.join(fileSeparator)
  
  loadPackage = (pkg) ->
    path = pkg.entryPoint or defaultEntryPoint
  
    loadPath(rootModule, pkg, path)
  
  loadModule = (pkg, path) ->
    unless (file = pkg.distribution[path])
      throw "Could not find file at #{path} in #{pkg.name}"

    unless (content = file.content)?
      throw "Malformed package. No content for file at #{path} in #{pkg.name}"
  
    program = annotateSourceURL content, pkg, path
    dirname = path.split(fileSeparator)[0...-1].join(fileSeparator)
  
    module =
      path: dirname
      exports: {}
  
    context =
      require: generateRequireFn(pkg, module)
      global: global
      module: module
      exports: module.exports
      PACKAGE: pkg

    args = Object.keys(context)
    values = args.map (name) -> context[name]
  
    Function(args..., program).apply(module, values)
  
    return module
  
  isPackage = (path) ->
    if !(startsWith(path, fileSeparator) or
      startsWith(path, ".#{fileSeparator}") or
      startsWith(path, "..#{fileSeparator}")
    )
      path.split(fileSeparator)[0]
    else
      false
  
  generateRequireFn = (pkg, module=rootModule) ->
    pkg.name ?= "ROOT"
    pkg.scopedName ?= "ROOT"

    fn = (path) ->
      if typeof path is "object"
        loadPackage(path)
      else if isPackage(path)
        unless otherPackage = pkg.dependencies[path]
          throw "Package: #{path} not found."
  
        otherPackage.name ?= path
        otherPackage.scopedName ?= "#{pkg.scopedName}/#{path}"
  
        loadPackage(otherPackage)
      else
        loadPath(module, pkg, path)

    Object.assign fn, publicAPI
  
    return fn

  startsWith = (string, prefix) ->
    string.lastIndexOf(prefix, 0) is 0

  cacheFor = (pkg) ->
    return pkg.cache if pkg.cache

    Object.defineProperty pkg, "cache",
      value: {}

    return pkg.cache

  annotateSourceURL = (program, pkg, path) ->
    """
      #{program}
      //# sourceURL=#{pkg.scopedName}/#{path}
    """

  # Generate source using Function#toString introspection
  generateSrc = ->
    src = """
      (function(create) {
        return create(create)
      }(#{create.toString()}))

    """

  publicAPI =
    generateFor: generateRequireFn

    packageWrapper: (pkg, code) ->
      pkgStr = JSON.stringify(pkg, null, 2)
      
      """
        (function(PACKAGE) {
          var require = #{generateSrc()}.generateFor(PACKAGE);
          #{code};
        })(#{pkgStr});
      """

    executePackageWrapper: (pkg) ->
      publicAPI.packageWrapper pkg, "require.loadPackage(PACKAGE)"

    loadPackage: loadPackage

  if module?
    module.exports = publicAPI

  return publicAPI

# Invoke create with reference to itself so it can output its source later.
create create
