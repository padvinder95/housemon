module.exports = (primus) ->

  counter = 0
  primus.api.next = -> ++counter
