module.exports = (app, plugin) ->  
  app.on 'setup', ->

    # RPC demo, returns an increasing counter, callable from clients
    counter = 0
    app.host.view2_next = ->
      ++counter
