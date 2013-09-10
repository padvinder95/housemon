module.exports = (app, plugin) ->

  plugin.server = (primus) ->
    primus.on 'connection', (spark) ->
      spark.on 'data', (arg) ->
        switch
          when arg.constructor is String
            console.info 'primus', spark.id, ':', arg
          when Array.isArray arg
            spark.emit arg...
          when arg instanceof Object
            primus.emit 'spark', spark, arg
