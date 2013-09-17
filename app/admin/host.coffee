Q = require 'q'

module.exports = (app, plugin) ->
  app.on 'setup', ->

    app.host.admin_dbinfo = ->
      q = Q.defer()
      app.db.getPrefixDetails q.resolve
      q.promise
