fs = require('fs')
_ = require('underscore')
return console.log "You must supply a filename" if not process.argv.length > 2
return console.log "Build file does not exist" if not fs.existsSync process.argv[2]
fs.mkdirSync "modules", 0o744 if not fs.existsSync "modules"
  
parseCommand = (line) ->
  args = line.split " "
  command = args.shift().toLowerCase()
  return console.log "Command not found, skipping..." if not commands[command]
  commands[command](args.join " ")  

dependencies = {}
  
commands = 
  depend: (deps) ->
    console.log "DEPEND " + deps + " "
    deps = deps.split " "
    dependency = deps.shift()
    dependencies[dependency] = deps
  install: (item)->
    console.log "INSTALL " + item
    return console.log "\t" + item + " is already installed." if item in installedModules()
    performInstall item
  remove: (item)->
    console.log "REMOVE " + item
    return "\t" + item + " is still needed" if isNeeded item
    computeDependenciesAfterRemoval(item).forEach removeModule
    removeModule item
  list: ->
    console.log "LIST"
    installedModules().forEach (mod)->
      console.log "\t" + mod
  end: process.exit
  clean: ->
    installedModules().forEach removeModule
  
performInstall = (item, circular = [])->
  return console.log "ERROR: Dependency cycle detected on " + item if item in circular
  circular = circular.concat item
  if dependencies[item] then dependencies[item].forEach (dependency)->
    performInstall dependency, circular 
  return if item in installedModules()
  console.log "\tInstalling " + item
  installModule item
    
installModule = (module)->
  fs.writeFile "modules/" + module, "The " + module + " module!"
  
removeModule = (module)->
  console.log "\tRemoving " + module
  fs.unlinkSync "modules/" + module
  
installedModules = ->
  fs.readdirSync "modules/"

isNeeded = (item)->
  item in _(installedModules()).chain()
  .reject (installed)->
    installed == item
  .map (installed)->
    [installed, computeDependencies installed]
  .flatten()
  .unique()
  .value()
  
computeDependencies = (module, deps = [], circular = [])->
  return console.log "ERROR: Dependency cycle detected on " + module if module in circular
  return deps if not dependencies[module]
  dependencies[module].forEach (child)->
    deps.push child
    computeDependencies child, deps, circular.concat module
  _(deps).unique()
 
computeDependenciesAfterRemoval = (module)->
  keep = _(installedModules()).chain()
  .reject (mod)->
    mod == module
  .map (mod)->
    [mod, computeDependencies mod]
  .flatten()
  .unique()
  .value()
  _(computeDependencies module).reject (dep)->
    dep in keep
  
lineReader = require('readline').createInterface(input: require('fs').createReadStream('build.system'))
lineReader.on 'line', (line) ->
  parseCommand line
  
wait = ->
  setTimeout wait, 100000
  
wait()

  