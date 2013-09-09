{createLogStream,Replayer} = require './lib'

module.exports = (primus) ->

  createLogStream("#{__dirname}/20121130.txt.gz")
    .pipe(new Replayer)
    .on 'data', (data) ->
      console.log 'e99', data
