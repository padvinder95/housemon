# Briqs are the installable modules in the ./briqs/ directory

ss = require 'socketstream'
fs = require 'fs'

# see https://github.com/socketstream/socketstream/issues/362
ss.api.remove = (name) ->
  delete ss.api[name]

installed = {}

module.exports = (state) ->
  
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
