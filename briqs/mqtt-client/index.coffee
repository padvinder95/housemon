exports.info =
  name: 'mqtt-client'
  description: 'Subscribe to an MQTT message broker and collect readings'
  packages:
    'mqtt': '*'

exports.factory = require './mqtt-client'
