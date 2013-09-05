exports.info =
  version: '0.1.0'
  name: 'sandbox'
  description: 'The Sandbox page is for trying out whatever you like'
  descriptionHtml: 'The Sandbox page is for trying out "whatever" you like.<br/>More information about this Briq can be obtained from the [about] link above.<br/>General information about Briqs can be found [here](/docs/#briqs.md), and more specific notes about Briq development can be found [here](/docs/#briq-api.md).' 
  author: 'jcw'
  authorUrl: 'http://jeelabs.org/about/'
  briqUrl: '/docs/#sandbox.md'
  menus: [
    title: 'Sandbox'
    controller: 'SandboxCtrl'
  ]

  
  
class Sandbox 

  
  constructor: -> 
    #do nothing
    @_debug = false
    @someprop = false
    @badprop = true
  
  #simple debug api methods
  setDebug : (flag) =>
    return @_debug = flag
  
  getDebug : () =>
    return @_debug 
  
  setConfig : (obj) =>
    if obj?.SomeProp?    
      @someprop = obj.SomeProp
  
  dump : () =>
    #example to serialize without @badprop (as opposed to generic dump on bob)
    #to show value of implementing dump() on object.
    return JSON.stringify @, (key, value) ->
      if key == 'badprop'
        return undefined
      
      return value
        
  inited : () =>
    #this module has (optionally) be sent setDebug() and setConfig() by this time.
  
    
exports.factory = Sandbox
    