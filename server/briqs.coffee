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
        installed[obj.key] = info: briq.info
        if briq.factory
          args = obj.key.split(':').slice 1
          installed[obj.key].bob = new briq.factory(args...)
        ss.api.add name, briq[name]  for name in briq.info.rpcs ? []

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
