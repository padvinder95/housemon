module.exports = (app, info) ->
  counter = 0
  app.api.next = -> ++counter
