{Logger} = require './lib'
{Replayer,createLogStream} = require '../replay/lib'

module.exports = (app, primus) ->

  createLogStream('app/replay/20121130.txt.gz')
    .pipe(new Replayer)
    .pipe(new Logger)

