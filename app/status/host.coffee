module.exports = (app, plugin) ->  
  app.on 'setup', ->

    app.host.status_driverinfo = ->
      app.registry.driver
