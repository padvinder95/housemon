stream = require 'stream'
fs = require 'fs'

module.exports = (app, plugin) ->
  registry = app.registry
  drivers = {}

  class Dispatcher extends stream.Transform
    constructor: () ->
      super objectMode: true
      
    _transform: (data, encoding, done) ->
      # locate the proper driver, or set a new one up
      name = registry.nodemap[data.type]
      unless drivers[name]
        driverProto = registry.driver?[name]
        unless driverProto?.decode
          console.log "driver (#{data.type})", data.msg
          return done()
        drivers[name] = Object.create driverProto
      
      out = drivers[name].decode data

      pushOne = (msg) =>
        if msg.tag
          data.tag = msg.tag
          delete msg.tag # TODO: prefer a shallow copy?
        else
          delete data.tag
        data.type = name
        data.msg = msg
        @push data

      if Array.isArray out
        pushOne x  for x in out
      else
        pushOne out  if out?
      done()

  app.register 'pipe.dispatcher', Dispatcher
  
  # load all the files found in this folder, so they can register themselves
  fs.readdirSync(__dirname).forEach (file) ->
    unless file is 'host.coffee'
      driver = require "./#{file}"
      if typeof driver is 'function' and driver.length is 1 # i.e. one arg
        driver app
