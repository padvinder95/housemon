# Contributed by Francois Hug, 2013-03-19

exports.info =
  name: 'emoncms'
  description: 'Log incoming readings to Emoncms'
  connections:
    feeds:
      # Gets readings collection, as inputs are already labeled from driver.
      'readings': 'collection'
  settings:
    server:
      title: 'Emoncms server and path'
      default: 'http://localhost/emoncms'
    apikey:
      title: 'Emoncms secret API key'
      default: 'xxxxxxxxxxxxxxxxxxx'

state = require '../server/state'
http = require 'http'
_ = require 'underscore'

exports.factory = class
  
  constructor: ->
    state.on 'set.readings', @processReading
          
  destroy: ->
    state.off 'set.readings', @processReading

  processReading: (obj, oldObj) ->
    return unless obj # ignore deletions
  
    time = obj.time / 1000            # packet time as unix seconds
    from = _.first obj.key.split '.'  # e.g. RF12:5:17
    node = _.last from.split ':'      # nodeid of sending node

    # Build url to send node data. Sends node ID, packet time, JSON key/values
    json = JSON.stringify _.omit obj, 'id', 'key', 'time'
    query = "apikey=#{@apikey}&node=#{node}&time=#{time}&json=#{json}"

    req = http.request "#{@server}/input/post?#{query}", (res) -> 
      res.on 'end', ->
        status = res.statusCode
        console.log "Emoncms -> Node #{node} = #{json}. HTTP#{status}"
      
    req.on 'error', (msg) ->
      console.log 'problem with request:', msg
    req.end
