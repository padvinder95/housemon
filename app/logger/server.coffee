module.exports = (app, primus) ->
  {Logger} = require './lib'
  {Replayer,createLogStream} = require '../replay/lib'

  createLogStream('app/replay/20121130.txt.gz')
    .pipe(new Replayer)
    .pipe(new Logger)

