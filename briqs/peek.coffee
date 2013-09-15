exports.info =
  version: '0.1.0'
  name: 'peek'
  description: 'Peek under the hood, look at server-side events'
  author: 'jcw'
  authorUrl: 'http://jeelabs.org/about/'
  briqUrl: '/docs/#peek.md'
  menus: [
    title: 'Peek'
    controller: 'PeekCtrl'
  ]

state = require '../server/state'
ss = require 'socketstream'

exports.factory = class
  
  constructor: ->
    @_debug = false

    state.onAny  listener

  #simple debug api methods
  setDebug : (flag) =>
    return @_debug = flag
  
  getDebug : () =>
    return @_debug 
  
  setConfig : (obj) =>

  inited : () =>
    #this module has (optionally) be sent setDebug() and setConfig() by this time.

    
  destroy: ->
    state.offAny  listener

listener = (args...) ->
  console.info 'PEEK>', @event, args... if @_debug
  try
    ss.api.publish.all 'ss-peek', @event, args...
  catch err
    #one such error would be cyclic errors when objects within args... are serialized during transport.
    console.log "PEEK not publishing #{@event} because error: #{err}" 
  finally
  
  
  