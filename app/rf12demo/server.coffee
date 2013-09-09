# backing out of the Lua driver experiment for now
# see https://github.com/jcw/housemon/issues/94
# and commit 40f4d72fda46a1308fecdae9cce9f87d7c85817c

{Serial,Parser,Decoder} = require './streamers'

module.exports = (primus) ->
  port = new Serial 'usb-A900ad5m'
  port.on 'open', ->
    port.pipe(new Parser).pipe(new Decoder).on 'data', (data) ->
      console.log 'RF12 out:', data
