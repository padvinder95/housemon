###
#   BRIQ: rf12registry 
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
#
###


#state obtained so we can refer to it in exports if needed
state = require '../server/state'

#the one and only instance we obtain everything else from.
RF12RegistryManager = require('./rf12registrymanager.coffee').RF12RegistryManager

exports.info =
  version: '0.1.0'
  name: 'rf12registry'
  description: 'An RF12Registry to enable compatible RF12 Writers to register their write interface.'
  descriptionHtml: 'This module allows other RF12 compatible "write" aware modules to register their ability to handle write requests for matching frequency and band patterns.<br/>More information can be obtained from the [about] link above.' 
  author: 'lightbulb'
  authorUrl: 'http://thedistractor.github.io/'
  briqUrl: '/docs/#briq-rf12registry.md'
  #TODO: Hook back the GUI and RPC for management and control capability
  #this revision is not supplied with the registry GUI (supplies management and monitoring facilities)
  #menus: [
  #  title: 'Rf12registry'
  #  controller: 'Rf12registryCtrl'
  #]

  #TODO: outputs capabulity not currently in jcw 0.6.0 branch yet, so removed from this build
  #outputs: 
  #  getDevices:
  #    title: 'Currently connected devices'
  #  getPatterns:
  #    title: 'Currently registered write patterns'
  #  getTransforms:
  #    title: 'Currently registered write transformers'
  #  loadTransform:
  #    title: 'dynamically load a new write transform'  

class RF12RegistryShell 
  _registry = null #static
  _debug : true
  
  constructor: -> 
    console.log "about to create 'the' registry..." if @_debug
    @_registry = new RF12RegistryManager.Registry() #this will broadcast in 50ms if its not already alive
    console.log "registry instantiated:", @_registry if @_debug
    return @_registry  

  getDevices: () =>
    if @_registry?
      return devices = @_registry.getDevices()

  #getPatterns: () =>

  #getTransforms: () =>
  
  #loadTransform: () =>
  
  #provides the created instance with some 'briq' identity if it supports it. NB: Needs admin patch from https://github.com/jcw/housemon/pull/69
  bobInfo: (bob) =>
    if @_registry.bobInfo?
      return @_registry.bobInfo( bob )    
      
  destroy: => 
   @_registry.destroy()

exports.factory = RF12RegistryShell



