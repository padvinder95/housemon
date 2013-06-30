exports.info =
  name: 'rrdarchive'
  description: 'Archival data storage using rrdtool'
  rpcs: ['rawRange']
  connections:
    feeds:
      'status': 'collection'
      'reprocess.status': 'event'
      'minutes': 'event'
    results:
      'rrdarchive': 'dir'
  downloads:
    '/rrdarchive': './rrdarchive'
  
state = require '../server/state'
fs = require 'fs'
async = require 'async'
_ = require 'underscore'

ARCHIVE_PATH = './rrdarchive'
ARCHREQ_PATH = '../rrdarchive'
ARCHMAP_PATH = './rrdarchive/index.json'
RRDTOOL_PATH = '/usr/bin/rrdtool'

spawn = require("child_process").spawn

archMap = null
rrdtool = null

setup = ->
  fs.mkdir ARCHIVE_PATH, -> # ignore mkdir errors (it probably already exists)

  if fs.existsSync ARCHMAP_PATH
    archMap = require ARCHREQ_PATH
    console.info 'archMap', archMap._
  else
    archMap = _: 0 # sequence number

  console.info "rrdtool: starting"
  rrdtool = spawn(RRDTOOL_PATH, ["-", ARCHIVE_PATH])
  rrdtool.stdout.on "data", (data) ->
    console.log "rrdtool: #{data}"

shutdown = ->
  rrdtool.stdin.end()
  console.info "rrdtool: stopped"

occasionalMapSave = _.debounce ->
  fs.writeFile ARCHMAP_PATH, JSON.stringify archMap, null, 2
, 3000

# also aggregates all reprocessed values, collecting the results in memory
# TODO need to flush more often, since complete reprocess will fill up memory
#   perhaps track these slots and trigger on reprocess.{start,end} events?

archiveValue = (time, param, value) ->
  # lookup (or assign and store) the id of the named parameter
  unless archMap[param]?
    archMap[param] = ++archMap._
    occasionalMapSave()
  id = archMap[param]

  path = "#{id}.rrd"
  if !fs.existsSync "#{ARCHIVE_PATH}/#{path}"
    rrdtool.stdin.write "create #{path} --step 60 DS:value:GAUGE:300:U:U RRA:AVERAGE:0.5:5:288 RRA:AVERAGE:0.5:30:336 RRA:AVERAGE:0.5:120:360 RRA:AVERAGE:0.5:1440:360 RRA:MAX:0.5:120:360 RRA:MAX:0.5:1440:360 RRA:MIN:0.5:120:360 RRA:MIN:0.5:1440:360\n"
    console.info "rrdtool: created #{path}"

  unixtime = time/1000.0
  console.info "update #{path} #{unixtime}:#{value}"
  rrdtool.stdin.write "update #{path} #{unixtime}:#{value}\n"

storeValue = (obj, oldObj) ->
  archiveValue obj.time, obj.key, obj.origval

# callable from client as rpc
exports.rawRange = (key, from, to, cb) ->
  now = Date.now()
  now = now - (now % 60000)
  from += now  if from < 0
  to += now  if to <= 0
  id = archMap[key]

  if !id
    console.info "rrdfetch: Unknown id #{id}"
    cb null, []
    return

  rawdata = ""
  console.log "rrdfetch: #{key},#{id},#{from/1000},#{to/1000}"
  rrdfetch = spawn(RRDTOOL_PATH, ["fetch", "#{ARCHIVE_PATH}/#{id}.rrd", "AVERAGE", "-s", "epoch+#{from/1000}s", "-e", "epoch+#{to/1000}s"], { stdio: ['ignore','pipe',process.stderr] })
  rrdfetch.stdout.on "data", (data) ->
    rawdata += data
  rrdfetch.stdout.on "close", ->
    res = []
    rawdata.trim().split("\n").filter (line) ->
      return line && line.match(/:\s+/)
    .map (line) ->
      return line.trim().split(/:\s+/)
    .filter (vals) ->
      return vals[0] < (to/1000)
    .map (vals) ->
      res.push parseFloat(vals[1])      # Push value first
      res.push parseFloat(vals[0])*1000 # Then timestamp
    console.log "rrdfetch: #{res}"
    cb null, res

exports.factory = class
  constructor: ->
    setup()
    state.on 'set.status', storeValue
    state.on 'reprocess.status', archiveValue
  destroy: ->
    state.off 'set.status', storeValue
    state.off 'reprocess.status', archiveValue
    shutdown()
