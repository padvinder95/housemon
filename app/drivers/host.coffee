stream = require 'stream'
fs = require 'fs'

module.exports = (app, plugin) ->
  knownDrivers = app.registry.driver ?= {}

  drivers =
    unknown:
      decode: (data) ->
        console.log "driver (#{data.type})", data.msg

  findDriver = (type) ->
    name = app.registry.nodemap[type]
    unless drivers[name]
      unless knownDrivers[name]
        return drivers.unknown
      drivers[name] = knownDrivers[name] # TODO: make a copy
    drivers[name]
  
  class Dispatcher extends stream.Transform
    constructor: () ->
      super objectMode: true
    _transform: (data, encoding, done) ->  
      driver = findDriver data.type, app.registry.nodemap
      unless driver
        console.log 'e66', data
      out = driver.decode data
      if Array.isArray out
        for x in out
          data.msg = x
          @push data
      else if out?
        data.msg = out
        @push data
      done()

  app.register 'pipe.dispatcher', Dispatcher
  
  fs.readdirSync(__dirname).forEach (file) ->
    unless file is 'host.coffee'
      driver = require "./#{file}"
      if typeof driver is 'function'
        driver app
