stream = require 'stream'

class ReadingLog extends stream.Writable
  constructor: (@db) ->
    super objectMode: true

  _write: (data, encoding, done) ->
    if data?
      {type,tag,time,msg} = data
      if type? and tag? and time? and msg?
        key = "reading~#{type}~#{tag}~#{time}"
        @db.put key, msg, done
      else
        console.warn 'reading log data ignored', data
        done()

class StatusTable extends stream.Writable
  constructor: (@db) ->
    super objectMode: true

  _write: (data, encoding, done) ->
    if data?
      {type,tag,time,msg} = data
      if type? and tag? and time? and msg?
        batch = @db.batch()
        for name, value of msg
          key = "#{type}/#{tag}/#{name}"
          batch.put "status~#{key}", { key, value, type, tag, time }
        batch.write done
      else
        console.warn 'status table data ignored', data
        done()

module.exports = (app, plugin) ->
  app.register 'sink.readinglog', ReadingLog
  app.register 'sink.statustable', StatusTable
