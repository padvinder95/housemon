module.exports = (app, plugin) ->
  app.on 'running', (primus) ->
    primus.on 'connection', (spark) ->
      
      spark.client('view1_twice', 123).then (res) ->
        console.log 'double', res
