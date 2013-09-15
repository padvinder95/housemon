###
#   BRIQ: rf12input 
#   Version: 0.1.2
#   Author: lightbulb -at- laughlinez (dot) com
#           https://github.com/TheDistractor
#   more info at: http://thedistractor.github.io/housemon/rf12input.html
#
#   License: MIT - see http://thedistractor.github.io/housemon/MIT-LICENSE.html
#   
#   About:
#   Provides ability to accept input for write requests to RF12Registry, inputs include the following mechanisms:
#   
#   *sockets (tcp)
#   *sockets (udp)
#   *sockets (unix)
#
#   Additionally this Briq supplies a GUI interface via http://localhost<:port>/rf12input url within HouseMon
#
#
#   Updated: 0.1.1 - supports basic debug 
#                  - small tidyup
#                  - added in missing UDP listener
###


#we set our requires above exports so we can use them inline
net = require('net')
dgram = require('dgram')
Stream = require('stream')
readline  = require('readline')
state = require '../server/state'
ss = require 'socketstream'

exports.info =
  version: '0.1.2'  
  name: 'rf12input'
  description: 'Provides input support using multiple transports for the RF12 Registry Service'
  descriptionHtml: 'This module installs listeners on various transport mechanisms (like UDP/TCP/UNIX Sockets etc.) to help you establish write requests to RF12Registry clients.<br />Use the link above to obtain the detailed manual.'
  author: 'lightbulb'
  authorUrl: 'http://thedistractor.github.io/'
  briqUrl: '/docs/#briq-rf12input.md'
  menus: [
    title: 'RF12input'
    controller: 'RF12inputCtrl'
  ]



#Registry is singleton
RF12RegistryManager = require('./rf12registrymanager.coffee').RF12RegistryManager


class RF12Input 

  
  constructor: -> 

  
    #setup instance variables
    @_debug = true
    @_registry = new RF12RegistryManager.Registry() #this will broadcast in 50ms
    
    @fs = require('fs');

    #should have these as configurations - next rev?
    @TCP_PORT = 3334
    @UDP_PORT = 3334
    @DOMAIN_SOCK = '/tmp/rf12input.sock'
    @Dserver = {} #domain socket object
    @Tserver = {} #tcp socket object
    @Userver = {} #udp socket object

      
  inited: ->


    #try to remove our domain socket incase it was left hanging.
    try
      @fs.unlinkSync @DOMAIN_SOCK
    catch error
      #just ignore
    finally
      #just continue

  
    self = @

    
    #lets start listening to writes
    state.on 'rf12.write', @RF12WriteListener 
    
    #===========================================
    #create a unix domain socket server
    @Dserver = net.createServer (socket) -> 
      socket.on 'connect', (listener) ->
        console.log "Socket client connect" if self._debug
        self.help socket

      
      rl = readline.createInterface socket, socket


      rl.on 'line', (line) =>
        self.processInput line, socket
      
      socket.on 'error', (err) =>
        console.log "DSock Error: #{err}" if self._debug
      
      socket.on 'end', () -> 
        console.log 'server disconnected' if self._debug
  
    @Dserver.listen @DOMAIN_SOCK, () ->
      console.log 'Domain server bound: ' + self.DOMAIN_SOCK if self._debug
      
    #============================================
 

    #============================================
    #create TCP socket server
    @Tserver = net.createServer (socket) -> 
      socket.on 'connect', (listener) ->
        console.log "Socket client connect" if self._debug
        self.help socket

      
      rl = readline.createInterface socket, socket


      rl.on 'line', (line) =>
        self.processInput line, socket
       
      socket.on 'end', () -> 
        console.log 'server disconnected' if self._debug
  
    @Tserver.listen @TCP_PORT, () ->
      console.log 'tcp server bound :' + self.TCP_PORT if self._debug
    #===============================================

    #============================================
    #create UDP socket server
    @Userver = dgram.createSocket ('udp4')
    
    @Userver.on 'listening', () =>
      address = @Userver.address()
      console.log "UDP Bound to #{address.address} #{address.port}"  if self._debug
    
    @Userver.on 'message', (msg,rinfo) ->
        console.log "UDP Socket client connect" if self._debug

        #simulate readline behaviour (rough but ready - removes trailing \n)
        buf = msg
        for i in [ (msg.length - 1 ) .. 0]
          if msg[i] == '\n'.charCodeAt(0)
            msg[i] = 0
            buf = msg.slice 0, i
            break

        hlp = self.getHelp()
        
        #Note - this requires Streams2 on node 0.10+
        ws = new Stream.Writable
        ws._write = (chunk,enc,next) ->
              
          self.Userver.send chunk, 0, chunk.length, rinfo.port,rinfo.address, (err, bytes) =>
            console.log "UDP Sent #{bytes} bytes"  if self._debug
          next()
        
        ws.write hlp

        #note: unlikely but possible for packet to be fragmented and msg would not be a full command sequence
        #this would require a more robust readline style buffer.
        self.processInput buf.toString(), ws
      
        ws.end()
      
       
    @Userver.on 'close', () -> 
        console.log 'UDP server disconnected' if self._debug
  
      
    @Userver.bind @UDP_PORT 
      
    #===============================================
    
  setDebug : (flag) =>
    return @_debug = flag
  getDebug : () =>
    return @_debug 
  setConfig : (obj) =>
    if obj?.DomainSocket?    
      @DOMAIN_SOCK = obj.DomainSocket
    if obj?.Port?    
      @TCP_PORT = obj.Port
    if obj?.UDPPort?    
      @UDP_PORT = obj.UDPPort
      
  
  help: (obj) =>
    console.log obj.write?
    if obj.write? 
      obj.write @getHelp()
    else
      return @getHelp()
  
  getHelp: () =>
    return new Buffer "syntax send <band> <group> <node> <header> <command>\n"
  

  
  processInput: (line, stream) =>
    console.log 'Processing:' + line if @_debug
    stream.write 'Processing: ' + line + '\n'
    input = line.split ' ' #action[0] band[1] group[2] nodeid[3] header[4] command[5]...
    if input.length >= 6 #stops reversal
        input[5]=(input.splice(5).join(' '))

    if (input.length >= 6) && (input[0] == 'send')
      
      key = +(new Date() ) #create a ms key
      @send input[1], input[2], input[3], input[4], input[5], key 
      stream.write "Transaction #{key} Sent\n"
    else
      stream.write "do you need syntax help?\n"


  send: (band, group, nodeid, header, data, key) =>
  
    console.log "########input-#{band}-#{group}-#{nodeid}-#{header}-#{data}" if @_debug

    #if the write happens state will emit an rf12.write event
    return  @_registry.write band, group, nodeid, header, data

  #wake up when we see rf12.write events and route then to ss (for ng's RF12inputCtrl to use)   
  RF12WriteListener: (data) =>
    console.log "RF12Write Called within RF12Input Briq -> about to call socketstream ss.api.publish.all 'ss-rf12-write'"  if @_debug
    console.log "Data is:" , data if @_debug
    ss.api.publish.all 'ss-rf12-write', data

  close: =>
    console.log "Close() - rf12input" if @_debug
    state.off 'rf12.write', @RF12WriteListener
    try
      @_registry.destroy()
    catch err
    finally
    try
      @Dserver.close() 
    catch err
    finally
    try
      @Tserver.close()
    catch err
    finally
    try
      @Userver.close()
    catch err
    finally
    try
      @Dserver.unref()
    catch err
    finally
    try
      @Tserver.unref()
    catch err
    finally
    try
      @Userver.unref()
    catch err
    finally
  
    
    
  destroy: => 
    console.log "Destroy - cleaning up rf12input" if @_debug
    @close()

exports.factory = RF12Input



