module.exports = (app, plugin) ->
  
  app.on 'start', ->
    Logger = @registry.sink.logger
    Replayer = @registry.pipe.replayer
    Serial = @registry.interface.serial
    Parser = @registry.pipe.parser
    Decoder = @registry.pipe.decoder
    createLogStream = @registry.source.logstream

    createLogStream('app/replay/20121130.txt.gz')
      .pipe(new Replayer)
      .on 'data', (data) ->
        console.log 'e99', data.line
      .pipe(new Logger)

    new Serial('usb-A900ad5m')
      .on 'open', ->
        @
          .pipe(new Parser)
          .pipe(new Decoder)
          .on 'data', (data) ->
            console.log 'RF12 out:', data
