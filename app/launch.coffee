module.exports = (app) ->
  
  app.on 'start', ->
    console.log "plugins: #{Object.keys(@config.plugin)}"
  
  app.on 'ready', ->
    console.info "server listening on port :#{@config.port}"

  # debugging: log all app.emit calls
  appEmit = app.emit
  app.emit = (args...) ->
    console.log 'appEmit', args
    appEmit.apply @, args

  app.registry = {}

  app.register = (type, name, value) ->
    console.log "registry.#{type}.#{name} = #{typeof value}"
    @registry[type] ?= {}
    @registry[type][name] = value

  app.on 'start', ->
    Logger = @registry.sink.logger
    Replayer = @registry.pipe.replayer
    createLogStream = @registry.source.logstream
    Serial = @registry.interface.serial
    Parser = @registry.pipe.parser
    Decoder = @registry.pipe.decoder

    createLogStream('app/replay/20121130.txt.gz')
      .pipe(new Replayer)
      .pipe(new Logger)

    createLogStream("app/replay//20121130.txt.gz")
      .pipe(new Replayer)
      .on 'data', (data) ->
        console.log 'e99', data.line

    port = new Serial 'usb-A900ad5m'
    port.on 'open', ->
      port.pipe(new Parser).pipe(new Decoder).on 'data', (data) ->
        console.log 'RF12 out:', data

  # After having been called once on startup, this module turns itself into a
  # proxy for the global "app" object by adjusting its own exports object, so
  # "app = require 'launch'" becomes an easy way to get at the app object.
  module.exports = app
