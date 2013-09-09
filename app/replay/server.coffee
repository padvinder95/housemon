{createLogStream} = require './restream'

module.exports = (primus) ->

  createLogStream("#{__dirname}/20121130.txt.gz")
    .on 'data', (data) ->
      console.log 'e99', data
