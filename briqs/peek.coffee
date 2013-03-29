exports.info =
  name: 'peek'
  description: 'Peek under the hood, look at server-side events'
  menus: [
    title: 'Peek'
    controller: 'PeekCtrl'
  ]

state = require '../server/state'
ss = require 'socketstream'

exports.factory = class
  
  constructor: ->
    state.onAny  listener
        
  destroy: ->
    state.offAny  listener

listener = (args...) ->
  # console.info '>', @event, args...
  ss.api.publish.all 'ss-peek', @event, args...
