exports.info = 
  name: 'thermostaat'
  description: 'Thermostaat controller'
  menus: [
    title: 'Thermostaat'
    controller: 'ThermostaatCtrl'
  ]

state = require '../server/state'
ss = require 'socketstream'

exports.factory = class
  
  constructor: ->
    state.on 'rf12.packet', packetListener

  destroy: ->
    state.off 'rf12.packet', packetListener

packetListener = (packet, ainfo) ->
  if packet.id is 7 and packet.group is 136 and packet.buffer[1] is 7
    # todo: if packet.buffer[2] is 0, then send current setpoint!
    s = packet.buffer[2] / 10
    ss.api.publish.all 'ss-thermostaat', s
