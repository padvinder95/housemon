# Briqs are the installable modules in the ./briqs/ directory

ss = require 'socketstream'
fs = require 'fs'
local = require '../local'

# briqs configuration settings can now be found in local.json, under key "briqs"
briqConfig = local.briqs or {}

# see https://github.com/socketstream/socketstream/issues/362
ss.api.remove = (name) ->
  delete ss.api[name]

installed = {}

module.exports = (state) ->

  #lightbulb - currently used by admin rpc module
  # TODO: this should probably be replaced by a generic by-key find in models
  state.getBobByKey = (key) ->    
    for k,briq of installed
      #console.log "looking at briq: #{k}"
      if briq.bob?
        #console.log "got a bob for #{k}"
        if k == key
          return briq.bob
  
    return null  
  
  state.on 'set.bobs', (obj, oldObj) ->
    if obj?
      briq = state.models.briqs[obj.briq_id]
      if briq?
        console.info 'install briq', obj.key
        ss.api.add name, briq[name]  for name in briq.info.rpcs ? []
        # TODO nasty: the incoming obj is only used to copy some settings from
        # the actually installed bob is created using the briq's factory method
        installed[obj.key] ?= {}
        installed[obj.key].info = briq.info
        if briq.factory
          bob = installed[obj.key].bob
          unless bob
            args = obj.key.split(':').slice 1
            bob = new briq.factory(args...)
            bob.bobInfo?(obj) #who we are (for self referencing if we have the bobInfo method)
            #lightbulb - if we have a briq config json, we see if we need to set debug flags
            if briqConfig.debug?[obj.id]?
              console.log "Setting debug for: #{obj.key} to #{briqConfig.debug[obj.id]}" #this always logged to console
              bob.setDebug?(briqConfig.debug[obj.id]) #do we debug this instance t/f ?
            if bob.setConfig?
              for k,v of briqConfig.config
                if obj.key.match k
                  bob.setConfig?(v)
              
              
              
            installed[obj.key].bob = bob
          for k,v of briq.info.settings
            bob[k] = obj[k] ? v.default ? ''
          bob.inited?()

    else
      orig = installed[oldObj.key]
      if orig?
        console.info 'uninstall briq', oldObj.key
        ss.api.remove name  for name in orig.info.rpcs ? []
        orig.bob?.destroy?()
        delete installed[oldObj.key]

  loadFile = (filename) ->
    loaded = require "../briqs/#{filename}"
    if loaded.info?.name
      loaded.key = filename
      state.store 'briqs', loaded

  loadAll: (cb) ->
    # TODO: delete existing briqs
    # scan and add all briqs, async
    fs.readdir './briqs', (err, files) ->
      throw err  if err
      for f in files
        loadFile f  unless f[0] is '.'
      cb?()
    # TODO: need newer node.js to use fs.watch on Mac OS X
    #  see: https://github.com/joyent/node/issues/3343
    # fs.watch './briqs', (event, filename) ->
    #   ... briq event, filename
