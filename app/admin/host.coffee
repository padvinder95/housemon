Q = require 'q'

module.exports = (app, plugin) ->
  console.log 'admin hello'

  app.on 'setup', ->

    app.api.admin_dbinfo = ->
      q = Q.defer()
      app.db.getPrefixDetails q.resolve
      q.promise
