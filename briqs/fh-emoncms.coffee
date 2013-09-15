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
      default: 'xxxxxxxxxxxxxxxxxxxxxx'

state = require '../server/state'
http = require 'http'
_ = require 'underscore'

exports.factory = class
  
  constructor: ->
    state.on 'set.readings', @processReading
          
  destroy: ->
    state.off 'set.readings', @processReading

  processReading: (obj, oldObj) =>
    return unless obj # ignore deletions
  
    time = obj.time / 1000            # packet time as unix seconds
    from = _.first obj.key.split '.'  # e.g. RF12:5:17
    node = _.last from.split ':'      # nodeid of sending node

    # Check if nodeid used by multiple nodes
    nodeLabel = _.last obj.key.split '.'
    nodeArr = nodeLabel.split '-'
    nodeNum = "" # Format string to append to key name. If nodeid shared: node11_temp_1
    if nodeArr.length >= 2
      nodeNum = '_' + nodeArr[1]
    # Build url to send node data. Sends node ID, packet time, JSON key/values
    json = '{'
    for param, value of _.omit obj, 'id', 'key', 'time'  # Build json string, renaming keys if needed
      json = json + '"' + param + nodeNum + '":' + value + ','
    json = json.substr(0,json.length-1) + '}'

    query = "apikey=#{@apikey}&node=#{node}&time=#{time}&json=#{json}"	

    req = http.request "#{@server}/input/post.json?#{query}", (res) =>
      res.on 'end', =>
        status = res.statusCode
        #console.log "Emoncms -> Node #{node} = #{json}. HTTP#{status}"
      
    req.on 'error', (msg) ->
      console.log 'problem with request:', msg
    req.write 'data\n'	#Needed by http.request method
    req.end
