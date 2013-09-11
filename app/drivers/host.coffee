stream = require 'stream'
fs = require 'fs'

module.exports = (app, plugin) ->
  registry = app.registry
  openDrivers = {}

  class Dispatcher extends stream.Transform
    constructor: () ->
      super objectMode: true
    _transform: (data, encoding, done) ->
      # locate the proper driver, or set a new one up
      name = registry.nodemap[data.type]
      unless openDrivers[name]
        driverProto = registry.driver?[name]
        unless driverProto?.decode
          console.log "driver (#{data.type})", data.msg
          return done()
        openDrivers[name] = Object.create driverProto
      
      out = openDrivers[name].decode data

      if Array.isArray out
        for x in out
          data.msg = x
          @push data
      else if out?
        data.msg = out
        @push data
      done()

  app.register 'pipe.dispatcher', Dispatcher
  
  # load all the files found in this folder, so they can register themselves
  fs.readdirSync(__dirname).forEach (file) ->
    unless file is 'host.coffee'
      driver = require "./#{file}"
      if typeof driver is 'function' and driver.length is 1 # i.e. one arg
        driver app
