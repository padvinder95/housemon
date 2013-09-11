module.exports = (app, plugin) ->
  
  app.register 'nodemap.rf12-868:42:2', 'testnode'
  
  app.register 'nodemap.rf12-2', 'roomnode'
  app.register 'nodemap.rf12-3', 'radioblip'
  app.register 'nodemap.rf12-4', 'roomnode'
  app.register 'nodemap.rf12-5', 'roomnode'
  app.register 'nodemap.rf12-6', 'roomnode'
  app.register 'nodemap.rf12-9', 'homepower'
  app.register 'nodemap.rf12-10', 'roomnode'
  app.register 'nodemap.rf12-11', 'roomnode'
  app.register 'nodemap.rf12-12', 'roomnode'
  app.register 'nodemap.rf12-13', 'roomnode'
  app.register 'nodemap.rf12-15', 'smarelay'
  app.register 'nodemap.rf12-18', 'p1scanner'
  app.register 'nodemap.rf12-19', 'ookrelay'
  app.register 'nodemap.rf12-23', 'roomnode'
  app.register 'nodemap.rf12-24', 'roomnode'

  app.on 'running', ->
    Logger = @registry.sink.logger
    Replayer = @registry.pipe.replayer
    Serial = @registry.interface.serial
    Parser = @registry.pipe.parser
    Dispatcher = @registry.pipe.dispatcher
    createLogStream = @registry.source.logstream

    createLogStream('app/replay/20121130.txt.gz')
      .pipe(new Replayer)
      .pipe(new Logger)
    
    createLogStream('app/replay/20121130.txt.gz')
      .pipe(new Replayer)
      .pipe(new Parser)
      .pipe(new Dispatcher)
      .on 'data', (data) ->
        console.log 'd18:', data
      .on 'error', (err) ->
        console.log 'x40', err

    new Serial('usb-A900ad5m')
      .on 'open', ->
        @
          .pipe(new Parser)
          .pipe(new Dispatcher)
          .on 'data', (data) ->
            console.log 'RF12 out:', data
          .on 'error', (err) ->
            console.log 'e81', err
