# This file is running on the 'server'
# These functions can be called from the client as: rpc 'docs.NAME', ...


local = require '../../local'

marked = require 'marked'

marked.setOptions
  sanitize:false
  

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


  

