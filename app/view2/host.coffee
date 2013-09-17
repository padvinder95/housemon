module.exports = (app, plugin) ->  
  app.on 'setup', ->

    counter = 0
    app.rpc.view2_next = ->
      ++counter
