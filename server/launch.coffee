# Web server startup, i.e. first code loaded from app.js

console.error 'pid', process.pid, Date() # mark new launch in the error log

# This list is also the order in which everything gets initialised
state = require './state'
briqs = require('./briqs') state
local = require '../local'
http = require 'http'
ss = require 'socketstream'
_ = require 'underscore'

# Auto-load all briqs from a central directory
briqs.loadAll ->
  console.info "briqs loaded"

# Hook state management into SocketStream
ss.api.add 'fetch', state.fetch
ss.api.add 'store', state.store
ss.api.add 'saveNow', state.saveNow
state.on 'publish', (hash, value) ->
  ss.api.publish.all 'ss-store', hash, value
  
# Define a single-page client called 'main'
ss.client.define 'main',
  view: 'index.jade'
  css: ['libs', 'app.styl']
  code: ['libs', 'app', 'modules']

# Serve this client on the root URL
ss.http.route '/', (req, res) ->
  res.serveClient 'main'

# Persistent sessions and storage based on Redis
ss.session.store.use 'redis', local.redisConfig
# ss.publish.transport.use 'redis', local.redisConfig
collections = ['bobs','readings','locations','drivers','uploads','status']
state.setupStorage collections, local.redisConfig, ->
  # set up download areas defined in any of the installed briqs
  for id, bob of state.models.bobs
    briq = state.models.briqs[bob.briq_id]
    for route, dir of briq?.info.downloads
      console.log 'downloads', route, dir
      # FIXME doesn't work yet, timing is too late, need to delay server start
      # ss.http.middleware.append route, ss.http.connect.directory dir
      # ss.http.middleware.append route, ss.http.connect.static dir

# Code Formatters known by SocketStream
ss.client.formatters.add require('ss-coffee')
ss.client.formatters.add require('ss-jade')
ss.client.formatters.add require('ss-stylus')

# Use client-side templates
ss.client.templateEngine.use 'angular'

# Minimise and pack assets if you type: SS_ENV=production node app.js
if ss.env is 'production'
  ss.client.packAssets()
else
  # show request log in dev mode
  # see http://www.senchalabs.org/connect/middleware-logger.html
  ss.http.middleware.prepend ss.http.connect.logger 'dev'

# support uploads, this will generate an 'upload' event with details
# TODO clean up files if this was not done by any event handlers
require('fs').mkdir './uploads', ->
ss.http.middleware.prepend ss.http.connect.bodyParser
  uploadDir: './uploads'
ss.http.middleware.prepend (req, res, next) ->
  state.emit 'upload', req.url, req.files  unless _.isEmpty req.files
  next()

# TODO find a way to put this code inside briqs, the archiver briq in this case
# support downloads from the "archive/" folder
ss.http.middleware.append '/archive', ss.http.connect.directory './archive'
ss.http.middleware.append '/archive', ss.http.connect.static './archive'
# support downloads from the "logger/" folder
ss.http.middleware.append '/logger', ss.http.connect.directory './logger'
ss.http.middleware.append '/logger', ss.http.connect.static './logger'

# Start web server
server = http.Server ss.http.middleware
server.listen local.httpPort
ss.start server

# TODO need a better way to authenticate than this ugly HTTP access hack
ss.http.router.on '/authenticate', (req, res) ->
  accept = req._parsedUrl.query is local.password
  req.session.userId = if accept then 1 else undefined
  req.session.save (err) ->
    res.serve 'main'

# This event is periodically pushed to the clients to make them, eh, "tick"
# special care is taken to synchronise to the exact start of a clock second
setTimeout ->
  lastMinute = -1
  setInterval ->
    now = Date.now()
    ss.api.publish.all 'ss-tick', now
    # also emit events once each exact minute for local cron-type uses
    minutes = (now / 60000 | 0) % 60
    if minutes isnt lastMinute
      if lastMinute >= 0
        console.log Date()
        state.emit 'minutes', minutes
      lastMinute = minutes
  , 1000
, 1000 - Date.now() % 1000
