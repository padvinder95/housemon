module.exports = (app, plugin) ->
  
  app.register 'nodemap.rf12-868:42:2', 'testnode'

  app.on 'running', ->
    Logger = @registry.sink.logger
    Replayer = @registry.pipe.replayer
    Serial = @registry.interface.serial
    Parser = @registry.pipe.parser
    Decoder = @registry.pipe.decoder
    Dispatcher = @registry.pipe.dispatcher
    createLogStream = @registry.source.logstream
    
    createLogStream('app/replay/20121130.txt.gz')
      .pipe(new Replayer)
      .on 'data', (data) ->
        console.log 'e99', data.msg
      .pipe(new Logger)

    new Serial('usb-A900ad5m')
      .on 'open', ->
        @
          .pipe(new Parser)
          .pipe(new Dispatcher)
          .on 'data', (data) ->
            console.log 'RF12 out:', data
          .on 'error', (err) ->
            console.log 'e81', err
