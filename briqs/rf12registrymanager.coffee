<<<<<<< Updated upstream
###
#   rf12registrymanager 
#   Version: 0.1.0
#   Author: lightbulb -at- laughlinez (dot) com
#           https://github.com/TheDistractor
#   more info at: http://thedistractor.github.io/housemon/rf12registry.html
#
#   License: MIT - see http://thedistractor.github.io/housemon/MIT-LICENSE.html
#   
#   About:
#   A Gated class (RF12RegistryShell) that provides a singleton RF12Registry instance via a RF12RegistryManager class
#   see RF12RegistryManager and RF12Registry classes  
#
#   NOTE: We are kept in the briq folder, but are not really a briq, rather briq support, so we are not seen by briq loader
#         as we dont supply .info exports etc.
#
###

state = require '../server/state'

class RF12Registry #we don't extend with EventEmitter(2), we use the 'state' object to route events
  ###
  The RF12Registry class creates a simple registry for use by 'compatible' RF12Demo.10+ drivers
  to enable a simple 'write' interface. 
  By abstracting the 'write' transaction into a standardized format it can help 
  consumers to interface with the system.
  Registration is a loosely coupled affair using discovery events. 

  Specific RF12Demo drivers can elect not to join the registry by ignoring 'RegistryUp' events

  Provides enough flexibility such that a non RF12Demo driver can provide the relevant interfaces to the Registry to allow
  write operations.

  ###

  _debug     : true  #do we output console logs
  _bandInfo  : {315:{shortcode:3,drivercode:0}, 433:{shortcode:4,drivercode:1}, 868:{shortcode:8,drivercode:2}, 915:{shortcode:9,drivercode:3} } 
  _version   : "0.1.0"
  
  #we want this as a singleton (ID) here! 
  constructor: (@id) ->

    #instance variables
    @_enabled   = false #is our 'registry' open for business
    @_bobInfo   = null  #bob instantiation data
    @_handlers  = {}    #contains all the handlers for registered 'write' patterns


  
    #simulate being ready sometime in future
    setTimeout =>
      @registryReady(true)
    , 50

    
  #so we can dynamically find out who we are.
  className : () =>
    return "RF12Registry"

  instanceName : () =>
    return @id   
    
  version : () =>
    return @_version   

  #allows us to obtain some of the briq/bob identity information should we need it in future.  
  bobInfo: (bob) =>
    if bob?
      console.log "bobInfo supplied for: #{ JSON.stringify(bob) }" if @_debug 
      @_bobInfo = bob

    return @_bobInfo
    
    
  registryReady: (enabledFlag) =>
    @_enabled = enabledFlag
    console.log "Registry #{@instanceName()} is Ready:?" + @_enabled if @_debug

    self = this
    #tell the world we are a 'Registry' using 'state'
    state.emit 'RF12Registry.RegistryUp', self

    #and listen for future requests
    state.on 'RF12Registry.Report', @broadcast
    
  #we have been asked to report our availability
  broadcast : () =>
    self = this

    if @_enabled
      console.log "Broadcasting Registry #{@instanceName()}" if @_debug
      state.emit 'RF12Registry.RegistryUp', self
  
  
  #clients (rf12demo-readwrite etc) register writer patterns to the registry  
  register: ( handler, info, cb ) =>
    unless @_enabled
      if typeof cb == 'function'
        return cb( new Error("Registry is Disabled"), false )
      else
        return false
        
    #get the patterns from the handler
    console.log "Registering path #{info.path} for #{handler.deviceName()} with Registry:#{@instanceName()}"  if @_debug
    #TODO-2013-06-12: use different structure to create priority tree i.e 868/212 matches before 868/* or */*
    @_handlers[info.path] = {"handler":handler, "mask":info.mask} #this handler will handle writes for this pattern
    if typeof cb == 'function'
      return cb(null,true)
    else
      return true

  #client wants to uncouple from registry    
  deregister: (handler, cb ) =>
    console.log "Deregister request from : #{handler.deviceName()} on Registry:#{@instanceName()}" if @_debug
    console.log "Registry currently has #{Object.keys(@_handlers).length} handlers registered"  if @_debug
    for k, obj of @_handlers
      if obj.handler == handler
        console.log "Removing Handler #{k} for #{obj.handler.deviceName()}"  if @_debug
        delete @_handlers[k]
         
    console.log "Registry now has #{Object.keys(@_handlers).length} handlers registered"  if @_debug

    if typeof cb == 'function'
      return cb(null,true)
    else
      return true

  #list all connected devices
  getDevices: () =>
    devices = {}
    for k, obj of @_handlers
      unless devices[obj.handler.deviceName()]?
        devices[obj.handler.deviceName()] = []
        
      devices[obj.handler.deviceName()].push k

    return devices

    
  #take a request from a consumer and see if we can match to a provider  
  write : (band,group,node,header,data, key) =>
    #NB: 
    console.log "Write Request on Registry:#{@instanceName()} for: #{band} #{group} #{node} #{header} #{data}"  if @_debug

    _key = key
    if not _key #create a ms key if none provided
      _key = +(new Date())
    
    unless @_enabled
      console.log "Write Requests denied as Registry is disabled" if @_debug
      return null
    
    #quick band validation
    if false #we can do validation if needed?
      unless @_bandInfo[band]?
        console.log "Invalid Band: #{band}" if @_debug
        return null
    
    
    console.log "devices registered for write: ", JSON.stringify @getDevices() if @_debug
    #TODO-2013-06-12 - see priority tree TODO above    
    for k, obj of @_handlers
      console.log "Handler: #{k}, #{obj.handler.deviceName()}"  if @_debug
      #try and find a writer to handle this request
      re = new RegExp(k)
      match = re.exec "#{band}.#{group}"
      if match
        console.log "Found our handler #{k}@ with mask:#{obj.mask} for device:#{obj.handler.deviceName()}"  if @_debug
        
        #note: the entire escape issue is cludged currently and only works in the most 'basic' way
        #TODO: replace with a more fully featured parser with 'escapes'
        buffer = obj.mask
        buffer = @parseToken buffer, "{%B}", band                                #use full band data i.e 868 sent as 868
        buffer = @parseToken buffer, "{%b}", @_bandInfo[band]?.shortcode || band #use band shortcut i.e 868=8 if match
        buffer = @parseToken buffer, "{%g}", group
        buffer = @parseToken buffer, "{%i}", node
        buffer = @parseToken buffer, "{%h}", header
        buffer = @parseToken buffer, "{\\r}", "\r"                               #translate \r
        buffer = @parseToken buffer, "{\\n}", "\n"                               #translate \n
        buffer = @parseToken buffer, "{%s}", data
        
        #TODO: add back the time delay tokens {%d} where d is a digit i.e {%500} = 500ms
        delay = 500
        
        #call into the module that handles the write request
        obj.handler.clientWrite buffer, delay, _key
        if true  #TODO:keep logic tree and replace with combined answer from clientwrite and parameter driver      
          #tell listeners a write happened
          state.emit 'RF12Registry.write', {"datestamp":Date.now(),"device":obj.handler.deviceName(),"band":band,"group":group,"node":node,"header":header,"data":buffer}

        return _key #we managed a write
      
      
    return null #we never managed to write to anything

  # locate token and replace with tokenvalue
  #TODO: Add escape processing  
  parseToken: (input, token, tokenvalue) =>
    re = new RegExp(token, 'g')   
    return input.replace re, tokenvalue
    
    
  close :() =>
    self = this
    console.log "Registry closing: #{@instanceName()}" if @_debug
    
    state.emit 'RF12Registry.RegistryDown', self #trouble if someone hangs onto us after this event
    
    if typeof state.off is "function"
      state.off 'RF12Registry.Report', @broadcast
  
  destroy :() =>
    @close()
          


class RF12RegistryManager

  _instance = undefined
  _tracker  = 0
  
  @Registry: () -> #must be static otherwise we get lots of _instances
    _tracker++
    _instance ?= new RF12Registry 1 #the one and only
    
  @Tracker: () ->
    _tracker

    
exports.RF12RegistryManager = RF12RegistryManager    
 
=======
###
#   rf12registrymanager 
#   Version: 0.1.0
#   Author: lightbulb -at- laughlinez (dot) com
#           https://github.com/TheDistractor
#   more info at: http://thedistractor.github.io/housemon/rf12registry.html
#
#   License: MIT - see http://thedistractor.github.io/housemon/MIT-LICENSE.html
#   
#   About:
#   A Gated class (RF12RegistryShell) that provides a singleton RF12Registry instance via a RF12RegistryManager class
#   see RF12RegistryManager and RF12Registry classes  
#
#   NOTE: We are kept in the briq folder, but are not really a briq, rather briq support, so we are not seen by briq loader
#         as we dont supply .info exports etc.
#
###

state = require '../server/state'

class RF12Registry #we don't extend with EventEmitter(2), we use the 'state' object to route events
  ###
  The RF12Registry class creates a simple registry for use by 'compatible' RF12Demo.10+ drivers
  to enable a simple 'write' interface. 
  By abstracting the 'write' transaction into a standardized format it can help 
  consumers to interface with the system.
  Registration is a loosely coupled affair using discovery events. 

  Specific RF12Demo drivers can elect not to join the registry by ignoring 'RegistryUp' events

  Provides enough flexibility such that a non RF12Demo driver can provide the relevant interfaces to the Registry to allow
  write operations.

  ###

  _debug     : true  #do we output console logs
  _bandInfo  : {315:{shortcode:3,drivercode:0}, 433:{shortcode:4,drivercode:1}, 868:{shortcode:8,drivercode:2}, 915:{shortcode:9,drivercode:3} } 
  _version   : "0.1.0"
  
  #we want this as a singleton (ID) here! 
  constructor: (@id) ->

    #instance variables
    @_enabled   = false #is our 'registry' open for business
    @_bobInfo   = null  #bob instantiation data
    @_handlers  = {}    #contains all the handlers for registered 'write' patterns


  
    #simulate being ready sometime in future
    setTimeout =>
      @registryReady(true)
    , 50

    
  #so we can dynamically find out who we are.
  className : () =>
    return "RF12Registry"

  instanceName : () =>
    return @id   
    
  version : () =>
    return @_version   

  #allows us to obtain some of the briq/bob identity information should we need it in future.  
  bobInfo: (bob) =>
    if bob?
      console.log "bobInfo supplied for: #{ JSON.stringify(bob) }" if @_debug 
      @_bobInfo = bob

    return @_bobInfo
    
    
  registryReady: (enabledFlag) =>
    @_enabled = enabledFlag
    console.log "Registry #{@instanceName()} is Ready:?" + @_enabled if @_debug

    self = this
    #tell the world we are a 'Registry' using 'state'
    state.emit 'RF12Registry.RegistryUp', self

    #and listen for future requests
    state.on 'RF12Registry.Report', @broadcast
    
  #we have been asked to report our availability
  broadcast : () =>
    self = this

    if @_enabled
      console.log "Broadcasting Registry #{@instanceName()}" if @_debug
      state.emit 'RF12Registry.RegistryUp', self
  
  
  #clients (rf12demo-readwrite etc) register writer patterns to the registry  
  register: ( handler, info, cb ) =>
    unless @_enabled
      if typeof cb == 'function'
        return cb( new Error("Registry is Disabled"), false )
      else
        return false
        
    #get the patterns from the handler
    console.log "Registering path #{info.path} for #{handler.deviceName()} with Registry:#{@instanceName()}"  if @_debug
    #TODO-2013-06-12: use different structure to create priority tree i.e 868/212 matches before 868/* or */*
    @_handlers[info.path] = {"handler":handler, "mask":info.mask} #this handler will handle writes for this pattern
    if typeof cb == 'function'
      return cb(null,true)
    else
      return true

  #client wants to uncouple from registry    
  deregister: (handler, cb ) =>
    console.log "Deregister request from : #{handler.deviceName()} on Registry:#{@instanceName()}" if @_debug
    console.log "Registry currently has #{Object.keys(@_handlers).length} handlers registered"  if @_debug
    for k, obj of @_handlers
      if obj.handler == handler
        console.log "Removing Handler #{k} for #{obj.handler.deviceName()}"  if @_debug
        delete @_handlers[k]
         
    console.log "Registry now has #{Object.keys(@_handlers).length} handlers registered"  if @_debug

    if typeof cb == 'function'
      return cb(null,true)
    else
      return true

  #list all connected devices
  getDevices: () =>
    devices = {}
    for k, obj of @_handlers
      unless devices[obj.handler.deviceName()]?
        devices[obj.handler.deviceName()] = []
        
      devices[obj.handler.deviceName()].push k

    return devices

    
  #take a request from a consumer and see if we can match to a provider  
  write : (band,group,node,header,data, key) =>
    #NB: 
    console.log "Write Request on Registry:#{@instanceName()} for: #{band} #{group} #{node} #{header} #{data}"  if @_debug

    _key = key
    if not _key #create a ms key if none provided
      _key = +(new Date())
    
    unless @_enabled
      console.log "Write Requests denied as Registry is disabled" if @_debug
      return null
    
    #quick band validation
    if false #we can do validation if needed?
      unless @_bandInfo[band]?
        console.log "Invalid Band: #{band}" if @_debug
        return null
    
    
    console.log "devices registered for write: ", JSON.stringify @getDevices() if @_debug
    #TODO-2013-06-12 - see priority tree TODO above    
    for k, obj of @_handlers
      console.log "Handler: #{k}, #{obj.handler.deviceName()}"  if @_debug
      #try and find a writer to handle this request
      re = new RegExp(k)
      match = re.exec "#{band}.#{group}"
      if match
        console.log "Found our handler #{k}@ with mask:#{obj.mask} for device:#{obj.handler.deviceName()}"  if @_debug
        
        #note: the entire escape issue is cludged currently and only works in the most 'basic' way
        #TODO: replace with a more fully featured parser with 'escapes'
        buffer = obj.mask
        buffer = @parseToken buffer, "{%B}", band                                #use full band data i.e 868 sent as 868
        buffer = @parseToken buffer, "{%b}", @_bandInfo[band]?.shortcode || band #use band shortcut i.e 868=8 if match
        buffer = @parseToken buffer, "{%g}", group
        buffer = @parseToken buffer, "{%i}", node
        buffer = @parseToken buffer, "{%h}", header
        
        #TODO: Add support for \x?? and \c?
        buffer = @parseToken buffer, "{\\\\x07}", "\x07"                             #translate \a
        buffer = @parseToken buffer, "{\\\\x1B}", "\x1B"                             #translate \e
        buffer = @parseToken buffer, "{\\\\f}"  , "\f"                               #translate \f
        buffer = @parseToken buffer, "{\\\\n}"  , "\n"                               #translate \n
        buffer = @parseToken buffer, "{\\\\r}"  , "\r"                               #translate \r
        buffer = @parseToken buffer, "{\\\\t}"  , "\t"                               #translate \t
        buffer = @parseToken buffer, "{\\\\v}"  , "\v"                               #translate \v
        
        buffer = @parseToken buffer, "{%s}", data
        
        #TODO: add back the time delay tokens {%d} where d is a digit i.e {%500} = 500ms
        delay = 500
        
        #call into the module that handles the write request
        obj.handler.clientWrite buffer, delay, _key
        if true  #TODO:keep logic tree and replace with combined answer from clientwrite and parameter driver      
          #tell listeners a write happened
          state.emit 'RF12Registry.write', {"datestamp":Date.now(),"device":obj.handler.deviceName(),"band":band,"group":group,"node":node,"header":header,"data":buffer}

        return _key #we managed a write
      
      
    return null #we never managed to write to anything

  # locate token and replace with tokenvalue
  #TODO: Add escape processing  
  parseToken: (input, token, tokenvalue) =>
    re = new RegExp(token, 'g')   
    return input.replace re, tokenvalue
    
    
  close :() =>
    self = this
    console.log "Registry closing: #{@instanceName()}" if @_debug
    
    state.emit 'RF12Registry.RegistryDown', self #trouble if someone hangs onto us after this event
    
    if typeof state.off is "function"
      state.off 'RF12Registry.Report', @broadcast
  
  destroy :() =>
    @close()
          


class RF12RegistryManager

  _instance = undefined
  _tracker  = 0
  
  @Registry: () -> #must be static otherwise we get lots of _instances
    _tracker++
    _instance ?= new RF12Registry 1 #the one and only
    
  @Tracker: () ->
    _tracker

    
exports.RF12RegistryManager = RF12RegistryManager    
 
>>>>>>> Stashed changes
    