# These functions can be called from the client as: rpc 'host.NAME', ...

local = require '../../local'

exports.actions = (req, res, ss) ->

  req.use 'session'
  
  # rpc client access to the server-side ss object
  # FIXME ugly hack to password-protect any changes to briq objects
  api: (cmd, args...) ->
    if cmd is 'store' and args[0] is 'bobs'
      if req.session.userId isnt 1 and local.password
        console.info 'unauthorised store bobs (rpc)'
        return res null
    ss[cmd] args..., res

  authenticate: (password) ->
    if password is local.password
      req.session.setUserId 1
      res true
    else
      res 'access denied'
      
  logout: ->
    req.session.setUserId null
