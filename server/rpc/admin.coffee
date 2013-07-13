# This file is running on the 'server'
# These functions can be called from the client as: rpc 'admin.NAME', ...


local = require '../../local'
state = require '../state'

marked = require 'marked'

marked.setOptions
  sanitize:false


getBob = (key) ->    
  return state.getBobByKey(key)

exports.actions = (req, res, ss) ->

  req.use 'session'

  MarkdowntoHtml: (text) ->
      markdown = null #"Oops - Unable to display!"
      if text?
        try
          markdown = "<span class='markdownContainer'>" + marked(text) + "</span>"
        catch err
          console.log err
        finally
    
      return res null, markdown 

      
  #does the bob support ability to get/set debug flag    
  supportsDebug: (key) ->
    bob = getBob(key)
    #TODO: optimize away
    if ( bob?.setDebug? && bob?.getDebug? )
      return res null, true
    else
      return res null, false
  
  #all bobs support basic dump (JSON) but they can also supply .dump() for specific dump data
  supportsDump: (key) ->
    bob = getBob(key)
    #TODO: optimize away
    if bob?
      return res null, true
    else
      return res null, false
      
  #pass in a flag          
  setDebug: (key, flag ) ->
    bob = getBob(key)
    #TODO: optimize away
    if bob?.setDebug?
      v = bob.setDebug flag
      return res null, v
    else
      return res null, null

  #get the current flag
  getDebug: (key) ->
    bob = getBob(key)
    #TODO: optimize away
    if bob?.getDebug?
      return res null, bob.getDebug()
    else
      return res null, null
     
  
  #get some output for dump action
  BobtoJSON: (key ) ->
    bob = getBob(key)
    #TODO: optimize away
    try
    
      if bob?.dump?
        return res null, bob.dump()
      else
        console.log JSON.stringify(bob)
        return res null, JSON.stringify(bob)
    catch err
      return res null, err
    finally
    
      
