###
#   BRIQ: rf12demo-readwrite
#   Version: 0.1.0
#   Author: lightbulb -at- laughlinez (dot) com
#           https://github.com/TheDistractor
#   more info at: http://thedistractor.github.io/housemon/rf12demo-readwrite.html
#
#   License: MIT - see http://thedistractor.github.io/housemon/MIT-LICENSE.html
#   
#   About:
#   Encapsulates read/write of RF12Demo.10+ sketch
#
###


state = require '../server/state'
_ = require 'underscore'
ss = require 'socketstream'


exports.info =
  name: 'rf12demo-readwrite'
  description: 'Read/Write Serial interface for a device (e.g JeeNode) running a RF12demo.10+ compatible sketches.'
  descriptionHtml: 'Read/Write interface for <b>RF12Demo.10+</b> compatible devices.<br/>For JNu please check/amend baud rate.<br/>Additional settings are available once installed.<br/>For more information click the [about] link above.'
  author: 'lightbulb'
  authorUrl: 'http://thedistractor.github.io/'
  briqUrl: '/docs/#briq-rf12demo-readwrite.md'
  version: '0.1.0'
  inputs: [
    {
      name: 'Serial port'
      default: 'usb-AH01A0GD' # TODO: list choices with serialport.list
    }
    {    
      name: 'Baud Rate'
      default: 57600
    }
    {    
      name: 'Shell Version'
      default: '' #supply a fixed version (don't go using version cmd which can cause loop on some CLI's)
    }
    
  ]
  connections:
    packages:
      'serialport': '*'
    results:
      'rf12.announce': 'event'
      'rf12.packet': 'event'
      'rf12.config': 'event'
      'rf12.other': 'event'
      'rf12.sendcomplete':'event'
      'rf12.version':'event'
      'rf12.write': 'event'
      'rf12.processWriteQ':'event'
  settings:
    initcmds:
      title: 'Initial commands sent on startup'
    writemasks:
      title: 'write mask(s) [see documentation link above]'
      default: null
    commands:
      title: 'Add/Override default CLI commands'
      default: '{"version":"v\r","config":"?\r"}' 
      
serialport = require 'serialport'

class RF12demo_rw extends serialport.SerialPort

  constructor: (@deviceInfo, params...) ->

    #define our instance variables
    @_registry      = null                                             #the registry this instance will be connected to 
    @_writerConfigs = null                                             #supported writer patterns
    @_nodeConfig    = {band:null,group:null,nodeid:null,version:null}  #this nodes config data
    @_registered    = false                                            #have we registered our writers?
    @_writeable     = false                                            #can we support writes? (RF12Demo.10+)
    @_cliCommands   = {"version":"v\r", "config":"?\r"}                #supported by RF12Demo.10+
    @_debug         = true
    @_opened        = false
    @_options       = {baud:57600, version:null}                       #basic configuration options
  
    @_initCmdTimeOut= 500                                              #delay from inited() call to issue of initial commands like config / version
    @_writeQ        = []                                               #array of writes with associated delays
  
    #@_uniqueid      = null  #unused
  

    #continue with constructor
    
    self = this
    console.log "MoreParams:", params if @_debug
    
    #params... this will allow specification of other properties e.g baud rates, for instance running JNu's (@ 38400)  
    #keep @deviceInfo seperate from @device as we may perform manipulation
    #     to the raw deviceInfo handle before we get the final device but this is briq specific (e.g file:/tmp/serialdata.txt)
    @device = @deviceInfo
    console.log "RFDemo #{@device} created" if @_debug
    
    # support some platform-specific shorthands
    switch process.platform
      when 'darwin' then port = @device.replace /^usb-/, '/dev/tty.usbserial-'
      when 'linux' then port = @device.replace /^tty/, '/dev/tty'
      else port = @device
      
    
    if params?[0]? #new baud rate
      try
          @_options.baud = parseInt(params[0])
      catch err
        console.log "Constructor Baud Param Error:#{err}"     
      finally
      
    if params?[1]? #supply specific version 
      try
          @_options.version = params[1]    
      catch err
        console.log "Constructor Version Param Error: #{err}"
      finally
      
      
    baud = @_options.baud
      
    console.info "Port:" + port + " Baud:" + baud if @_debug
    # construct the serial port object
    super port,
      baudrate: baud
      parser: serialport.parsers.readline '\n'


    #[part of the RF12Registry Interface]
    state.on 'RF12Registry.RegistryUp' , self.registryUp
    
    #[part of the RF12Registry Interface]
    state.on 'RF12Registry.RegistryDown', self.registryDown


    console.log "Constructor completes for #{@device} #{JSON.stringify @_options} with config:#{ JSON.stringify @_nodeConfig}" if @_debug
    
    
  #allows us to find out what we are 'after the fact'
  className : () =>
    return 'RF12Demo_rw'
    
  deviceName : () =>
    return @device


  setup: ()=>


    setTimeout =>
      
      console.log "Setup params start for:#{@device} #{JSON.stringify @_options} - config:#{ JSON.stringify @_nodeConfig }" if @_debug
    
      if @initcmds
        console.log "Sending Init sequence to #{@device}" if @_debug
        @write @initcmds

      if @_options.version?
        @setVersion @_options.version
        
      #get the CLI to emit our config string, then chain to version unless supplied
      if @_cliCommands.config?
        setTimeout =>
          console.log "rf12 config request for:#{@device}" if @_debug
          @write @_cliCommands.config
        , 500 #should be enough time for CLI to be ready after init?? TODO:move to a config setting
      
    , @_initCmdTimeOut #how long to wait before we start the init process.

    return true    

  #process the RegistryUp state event  
  #[part of the RF12Registry Interface]
  registryUp : (theRegistry) =>
  
    console.log "#{@deviceName()} got a Registry Event from Registry:#{theRegistry.instanceName()}"  if @_debug
    #we only register if we are not already registered, we can use setRegistry for others
    unless @_registry?
      console.log "#{@deviceName()} Registering with Registry:#{theRegistry.instanceName()}"  if @_debug
      @setRegistry( theRegistry )
      @setWriteable( @_writeable ) #force re-evaluation

    return @_registry  
      
  #process the registryDown state event    
  #[part of the RF12Registry Interface]
  registryDown: (theRegistry) =>
    #only interested if its our stored registry
    if @_registry == theRegistry
      console.log "Registry is down, attempting deregister" if @_debug
      @setRegistry(null)
      @setWriteable( false )

    return @_registry  #should be null
  
  #Are we able to process write requests?
  #[part of the RF12Registry Interface]
  setWriteable : (flag) =>
    @_writeable = flag
    if @_writeable #try and register writers
      if @_registry #we have a registry
      
        #if we have already registered writers we should deregister to clear them
        if @_registered
          @_registry.deregister this
          @_registered = false
          
        if not @_registered
          console.log "setWriteable calls @writers for: #{@device}" if @_debug
          @writers @writemasks , (err,result) => 
          
      else #we dont have registry but we are able to write 
        console.log "Request Registry to Report...by:#{@device}" if @_debug
        state.emit 'RF12Registry.Report' #if RF12Registry is listening it will respond with RF12Registry.RegistryUp      

    return @_writeable
    
    
  #allows us to supply an 'RF12Registry' to use as a registration service
  #[part of the RF12Registry Interface]
  setRegistry : (registry) =>
    console.log "Registry SET called by: #{@device}" if @_debug
    if (@_registry != null) and (@_registry != registry) #we are told to use a registry but its different to one we previously registered on, so deregister writers
      console.log "Need to DEREGISTER:", @device  if @_debug
      @_registry.deregister this
      @_registered = false
    
    @_registry = registry
    #we actually register for writes when a config is available which could be sometime later

    if @_registry == null
      @_registered = false
    
    return @_registry
    
  #used to Queue writes via the RF12Registry interface to abstract the input format
  #NB: I'd like to have used Write, but because we inherit serial then thats taken, and we need to proxy. (TODO: super.write....)
  #[part of the RF12Registry Interface]
  clientWrite : (buffer, delayNext, key) =>
    result = false
    console.log "Writing #{escape(buffer)} to our device #{@deviceName()}" if @_debug
    console.log "#{buffer}" if @_debug
    
    if Buffer.isBuffer(buffer) #unsupported in this version
      console.log "....it was a raw buffer so pass it directly"  if @_debug    

    #we use a Q, so next version is able to 'split' writes into multiple actions in one transaction
    #and also allows us to send long running requests with less chance of the next write messing us up.    
    @_writeQ.push {"buffer":buffer, "delayNext":delayNext,"key":key}
    state.emit "rf12.processWriteQ", @device #re-starts the message pump
    result = true

    #TODO: revert to callback as per v0.2.0
    return result     
    
  #processed any queued writes  
  #[part of the RF12Registry Interface]    
  processWriteQ : (thedevice) =>
    
    if @device != thedevice
      return null #was not our event
    
    #schedule timeout to process queue
    if not @_delayWriteQ #we dont need to wait.
    
      writeObj = @_writeQ.shift() #get oldest message
      console.log "Q Entry: #{JSON.stringify writeObj }" if @_debug
      try  
        if writeObj?.buffer? #do we have writeObj with buffer
          console.log "Writing to device #{@device} the buffer: #{escape(writeObj.buffer)}" if @_debug

          @write writeObj.buffer
          #TODO: add the band/group/node data as it may be useful for listeners
          state.emit 'rf12.write', {"datestamp":Date.now(),"device":@deviceName(),"data":writeObj.buffer}
          
          if writeObj?.delayNext?  #we will delay the next write by .delayNext ms
            @_delayWriteQ = true
            setTimeout =>
              @restartWriteQ()
            , writeObj.delayNext
          else
            #we use events so as not to recurse
            #pump the queue
            state.emit "rf12.processWriteQ", @device #re-starts the message pump
          
                    
              
      catch err
        #do nothing
      finally
        #do nothing
    
    
    return writeObj #may be null, in which case q is empty

  #[part of the RF12Registry Interface]
  restartWriteQ: () =>  
    @_delayWriteQ = false
    state.emit "rf12.processWriteQ", @device #re-starts the message pump
    

    
  #called when a device config is obtained to register write paths with the registry  
  #[part of the RF12Registry Interface]
  writers : ( writerConfigs, callback ) =>
    #writeconfigs are treated as single tokenized strings '{%b}/{%g}|{%1}' or if begin with '[', JSON objects i.e. '["{%b}/{%g}|{%1}", "{%b}/200|{%1}"]'
    #NOTE: JSON objects must be correctly formed
    
    unless @_writeable
      console.log "Driver #{@deviceName()} is not currently write enabled" if @_debug
      return callback(null,false)

    unless writerConfigs
      console.log "No writeConfigs supplied" if @_debug
      return callback(null,false)
    
      
    console.log "RFDemo Writers: #{writerConfigs} for: #{@device}" if @_debug
    #when config arrives from device we merge to make patterns for registration
        
    #if first char is '[' we treat as JSON
    #otherwise we make into single dimension array
    #TODO: more elegant parse descision
    list = []
    if (writerConfigs.charAt(0) == '[') #or (writerConfigs.charAt(0) == '{')
      try
        list = JSON.parse( writerConfigs )
      catch err
        console.log "rf12demo-readwrite: JSON format suggested, but unable to parse - err:#{err}" 
      finally
    else
      list.push writerConfigs
      
    @_writerConfigs = [] #this will contain all the 'write' patterns we wish to support
    
    for p,i in list 
      [bgpat, dpat...] = p.split '|' #split writestring from radio match
      bgpat = bgpat.replace /{%b}/g , @_nodeConfig.band #TODO: This should really be %B
      bgpat = bgpat.replace /{%g}/g , @_nodeConfig.group
      bgpat = bgpat.replace /\//,'[.]' #turn / into dot
      #we now have a pattern that the 'registry' can regex to match for writes
      #this could be done in registry, but beneficial to keep a record in this object.

      if dpat?.length == 0 #never supplied anything after |
        dpat = ['{%1}'] #user did not supply write pattern, so we use default
      
      if dpat[0] == '{%1}' #translate into 'default' pattern for RF12Demo.10+
        if @_nodeConfig.version == 9
          dpat[0] = "{%s}" #using older bytes,nodeid 's' syntax (no band switch)
        else
          dpat[0] = "{%b},{%g},{%i},{%h},{%s}>" #using new .10+ syntax that can switch bands etc
      
      
      #keep a record
      @_writerConfigs.push {"path":bgpat, "mask": dpat[0] }
    
    #register this instance for each 'write' pattern
    if @_registry
      self = this
      for p,i in @_writerConfigs
        @_registered = true
        @_registry.register self, p
        
        
    return callback(null,@_registered)    
  
  #does our CLI meet the requirement to support writes?  
  #[part of the RF12Registry Interface]
  isWriteable : () =>
    canWrite = @_nodeConfig.band? and @_nodeConfig.group? and @_nodeConfig.nodeid? and (@_nodeConfig.version? and (@_nodeConfig.version >= 10))
    console.log "isWriteable evaluates to #{canWrite} for:#{@device}" if @_debug
    return canWrite
  
  #[part of the RF12Registry Interface]
  parseVersion : (thedevice,data,match) =>
    if @device != thedevice #its not our event
      return null
      
    console.log "#{@device} got a rf12.version message : #{match.slice(1)}" if @_debug   
    return @setVersion match.slice(1)
        
  #[part of the RF12Registry Interface]
  setVersion : (version) =>
    console.log "I am #{@device} in setVersion" if @_debug
    try
      if parseFloat(version) 
        @_nodeConfig["version"] = parseFloat(version).toFixed(2)
        if @_nodeConfig["version"] >= 10
          console.log "RF12 is a writable interface for: #{@device}" if @_debug
          console.log "#{@device} calling setWriteable with #{ JSON.stringify(@_nodeConfig) }" if @_debug
          @setWriteable @isWriteable()         
    catch err
    
    finally      
      
    return @_nodeConfig["version"]
  
        
  #[part of the RF12Registry Interface]
  parseConfig : (thedevice, data, match) =>
        console.log "event: rf12.config: from: #{thedevice} being reviewed by: #{@device}" if @_debug 
        if @device != thedevice #its not our event
          console.log "rf12.config rejected by: #{@device}" if @_debug
          return null


        @_nodeConfig["group"] = match[1]
        @_nodeConfig["band"] = match[2]
        @_nodeConfig["nodeid"] = match[0]

        console.log "#{@device} config data nodeid: #{@_nodeConfig.nodeid} group:#{@_nodeConfig.group} band:#{@_nodeConfig.band}" if @_debug

        #get the CLI to emit the version string unless we have been specifically told
        #what version we are to be
        unless @_nodeConfig.version?
          #but only if we have writers specified, as in the case 
          #of RF12Demo upto v10, does not support version cmd
          #and we dont need version if no writers specified
          if @writemasks?
            if @_cliCommands.version? #TODO:check we dont need this validation any more?
              setTimeout =>
                #this will cause endless loop for CLI's that dont respond to version, but instead re-issue config (like RF12Demo.9). 
                # solution: specify version in settings.
                #TODO: so we really need to put in a race gate counter of some type.
                @write @_cliCommands.version

              , 50
            else
              #no version cmd to use and no version specifically supplied           
              @setVersion('9')
          else
            unless @_cliCommands.version?
              @setVersion('9') #no version yet and no version command set, also no writers, assume v9
            

        @setWriteable @isWriteable()         

  #we got what we think is a reply from a write?          
  #[part of the RF12Registry Interface]
  sendComplete : (device, bytes) =>
        if device != @device #we never sent this as its not our device
          return null

        console.log "Sendcomplete for: #{device} with #{bytes} bytes"  if @_debug

        return bytes
  
  #This gets called when first instantiated, and again every time we commit the optional parameters (as we are re-inited every time)
  inited: ->
  
    self = this

    console.log "#{@device} is inited() with id:#{@_uniqueid} options:#{JSON.stringify @_options} config: #{JSON.stringify @_nodeConfig}" if @_debug
    
    
    try
      if @commands?
        #gui supplied some additional cli commands or overrides existing
        cmds = JSON.parse @commands
        @_cliCommands = _.extend @_cliCommands, cmds
        console.log "cliCommands now #{JSON.stringify(@_cliCommands)}" if @_debug
    catch err
      console.log "Parameter error:#{err} for :#{escape(@commands)} on #{@device}" if @_debug
    finally
    
    
    
    #inited is called everytime a gui parameter is changed (see debounce--replaced)    
    if @_opened #device is ready to recv
      console.log "Sending Startup for #{@device}..." if @_debug
      @setup() #causes config data to be captured then chained to version, if requested 
  
    @on 'close', =>
      console.log "Device closed..." + @device if self._debug
      @_opened = false    
    
    @on 'open', =>
      @_opened = true
      console.log "Port open..." + @device if self._debug

      @setup() #causes config data to be captured then chained to version 

      #TODO: These should be on the instance 
      info = {} #standard rf12demo format
      ainfo = {} #announcer info


      #does our instance have identity, if so we can listen for writes
      state.on 'rf12.config', self.parseConfig           #config is available
      state.on 'rf12.version', self.parseVersion         #version is available
      state.on 'rf12.sendcomplete', self.sendComplete    #message send confirmation
      state.on 'rf12.processWriteQ', self.processWriteQ  #check and pump messages
      
  
      @on 'data', (data) ->
        data = data.slice(0, -1)  if data.slice(-1) is '\r'
        if data.length < 300 # ignore outrageously long lines of text
          # broadcast raw event for data logging
          state.emit 'incoming', 'rf12demo', @device, data
          words = data.split ' '
          if words.shift() is 'OK' and info.recvid
            # TODO: conversion to ints can fail if the serial data is garbled
            info.id = words[0] & 0x1F
            info.buffer = new Buffer(words)
            if info.id is 0
              # announcer packet: remember this info for each node id
              aid = words[1] & 0x1F
              ainfo[aid] ?= {}
              ainfo[aid].buffer = info.buffer
              state.emit 'rf12.announce', ainfo[aid]
            else
              # generate normal packet event, for decoders
              state.emit 'rf12.packet', info, ainfo[info.id]
          else #something other than 'OK...'
            match = /^ -> (\d+) b/.exec data
            if match #we have results of a send from the mcu in the format ' -> x b' where x is bytes.
               state.emit 'rf12.sendcomplete', @device, match[1]
            else
              # look for config lines of the form: A i1* g5 @ 868 MHz
              match = /^ [A-Z[\\\]\^_@] i(\d+)\*? g(\d+) @ (\d\d\d) MHz/.exec data
              if match
                console.log "rf12demo-readwrite:#{@device} config match:" , data if self._debug
                info.recvid = parseInt(match[1])
                info.group = parseInt(match[2])
                info.band = parseInt(match[3])
                #console.log "emitting event rf12.config by: #{@device} | #{self.device}"                
                #state.emit 'rf12.config', (@device), data, match.slice(1)                
                self.parseConfig @device, data, match.slice(1)
              else
                #look for a reply from a version command 'v'
                match = /^\[RF12demo.(\d+)\]/i.exec data
                if match
                  console.log "rf12demo-readwrite:#{@device} version match:", data if self._debug
                  #state.emit 'rf12.version', (@device), data, match.slice(0)
                  self.parseVersion @device, data, match.slice(0)
                else  
                  # unrecognized input, usually a "?" line
                  state.emit 'rf12.other', data
                  console.info 'other', @device, data if self._debug


  close : () =>
    console.log "close() called" if @_debug

    #[part of the RF12Registry Interface]
    state.off 'RF12Registry.RegistryUp' , @registryUp
    state.off 'RF12Registry.RegistryDown', @registryDown
    state.off 'rf12.sendcomplete', @sendComplete
    state.off 'rf12.config', @parseConfig           
    state.off 'rf12.version', @parseVersion         
    state.off 'rf12.processWriteQ', @processWriteQ  


    if @_registry
      @_registry.deregister this
      
    @_registered = false
    @_writeable = false
    
    console.log "#{@deviceName()} has closed (and should be deleted)." if @_debug
                  
  destroy: -> 
    console.log "Destroy is calling close()" if @_debug
    @close()
        
exports.factory = RF12demo_rw
