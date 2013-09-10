module.exports = (app, primus) ->

  counter = 0
  app.api.next = -> ++counter
