module.exports = (app, plugin) ->
  
  counter = 0
  app.api.next = ->
    ++counter
