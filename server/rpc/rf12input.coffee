###
#   RPC Server: rf12input 
#   Version: 0.1.0
#   Author: lightbulb -at- laughlinez (dot) com
#           https://github.com/TheDistractor
#   more info at: http://thedistractor.github.io/housemon/rf12input.html
#
#   License: MIT - see http://thedistractor.github.io/housemon/MIT-LICENSE.html
#   
#   About:
#   Provides server RPC endpoints for rf12input 
#
#   NB: This file is running on the 'server'
#   These functions can be called from the client as: rpc 'rf12input.NAME', ...
###


local = require '../../local'
state = require '../state'
  
RF12RegistryManager = require('../../briqs/rf12registrymanager.coffee').RF12RegistryManager
_registry = new RF12RegistryManager.Registry() #this will broadcast in 50ms if not already alive

_debug = true

exports.actions = (req, res, ss) ->

  req.use 'session'


  #wrapper for the Registry's write method
  Write: (band,group,node,header,data) ->
    result = null
    console.log "Write Request from web for: #{band} #{group} #{node} #{header} #{data}" if _debug

    try
      #state will emit RF12Registry.write if a client is available and message passed
      #state will then emit rf12.write when driver writes to CLI
      #ss will emit ss-rf12-write when rf12input Briq sees rf12.write
      result = _registry.write band, group, node, header, data
      console.log "Registry Write returns:#{result}" if _debug
    catch err
      console.log "Write Error:", err
    finally
    
    return res null, result 
  


  

