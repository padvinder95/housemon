Q = require 'q'

module.exports = (app, plugin) ->
  app.on 'setup', ->

    app.rpc.admin_dbinfo = ->
      q = Q.defer()
      app.db.getPrefixDetails q.resolve
      q.promise
