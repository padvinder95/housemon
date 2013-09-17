module.exports = (app, plugin) ->

  plugin.server = (primus) ->
    app.rpc.broadcast = primus.write.bind primus
    
    primus.on 'connection', (spark) ->
      spark.on 'data', (arg) ->
        switch
          when arg.constructor is String
            console.info 'primus', spark.id, ':', arg
          when Array.isArray arg
            spark.emit arg...
          when arg instanceof Object
            app.emit 'spark', spark, arg
