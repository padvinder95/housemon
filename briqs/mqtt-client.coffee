exports.info =
  name: 'mqtt-client'
  description: 'Subscribe to an MQTT message broker and collect readings'
  connections:
    packages:
      'mqtt': '*'

mqtt = require 'mqtt' # https://github.com/adamvr/MQTT.js
state = require '../server/state'

PORT = 1883
HOST = '192.168.1.122'

sensorMap =
  '63828a4efa64b218cbf33f8cc80ba08e': 'living'
  'fe74efb250da37f7432ed1ae064ba83b': 'other'
  '32e928e8d51207421c1ad701bf8a5644': 'stove'

setupListener = ->
  client = mqtt.createClient PORT, HOST
  client.on 'connect', ->
    client.subscribe '/#'
    client.on 'message', (topic, message, packet) ->
      # console.log 'm', topic, message #, packet
      # broadcast raw event for data logging
      state.emit 'incoming', 'mqtt', 'mqtt', "#{topic} #{message}"
      match = topic.match /\/sensor\/(.+)\/gauge/
      sensor = sensorMap[match?[1]]
      if sensor
        [time,value,unit] = JSON.parse(message)
        state.store 'readings',
          time: time * 1000
          key: "flukso.#{sensor}"
          value: value
  client

exports.factory = class
  
  constructor: ->
    @client = setupListener()

  destroy: ->
    @client.end()
