module.exports = (app, plugin) ->
  
  app.on 'setup', ->

    counter = 0
    app.api.view2_next = ->
      ++counter
