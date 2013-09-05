# This file is running on the 'server'
# These functions can be called from the client as: rpc 'docs.NAME', ...


local = require '../../local'

fs = require 'fs'
path = require 'path'
marked = require 'marked'

marked.setOptions
  sanitize:false
  

exports.actions = (req, res, ss) ->

  req.use 'session'

  fpath = './docs'  
  
  list: (filterexpr) ->
    re = new RegExp(filterexpr)
    #console.log "Filtering:#{filterexpr}"
    
    fs.readdir fpath, (err,entrys) ->
      doclist = []
      #console.log entrys
      entrys.filter (v) ->
        re.test(v)       
      
      
      for entry in entrys
         stats = fs.statSync path.join(fpath,entry) #, (err, stats) ->
         if stats?
           if stats.isFile()
             doclist.push {name: entry,key:entry,date:stats.mtime.getTime()}
      
      return res null, doclist  
  
  get: (doc) ->
    fs.readFile path.join(fpath,doc.name), {encoding:"utf-8"}, (err, fdata) ->
      markdown = marked("Oops, That file could not be processed. Log an [issue](https://github.com/jcw/housemon/issues) ")
      
      try
        #tweak until i can submit pull to marked (buffer()/BOM issue)
        markdown = marked(fdata.toString() )
      catch err
        console.log err
      finally
    
      return res null, {name:doc.name,data:markdown}


  

