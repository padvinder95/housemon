# Graphs module definitions

module.exports = (ng) ->

  ng.controller 'GraphsCtrl', [
    '$scope','rpc',
    ($scope, rpc) ->

      $scope.setGraph = (key) ->
        period = ($scope.hours or 1) * 3600000
        promise = rpc.exec 'host.api', 'rawRange', key, -period, 0
        promise.then (values) ->
          return  unless values

          info = $scope.status.find key
          console.info "graph", values.length, key, info

          options =
            xaxis:
              mode: 'time'
              timeMode: 'local'
            yaxis:
              autoscale: true
            mouse:
              track: true
              sensibility: 10
              trackFormatter: myFormatter

          data = for i in [0...values.length] by 2
            [
              parseInt values[i+1]
              adjustValue parseInt(values[i]), info
            ]

          # TODO big nono: DOM access inside controller!
          chart = $('#chart')[0]
          graph = Flotr.draw chart, [ label: key, data: data ], options

      # TODO open page with fixed choice, for testing convenience only
      $scope.setGraph 'meterkast - Usage house'
  ]

myFormatter = (obj) ->
  # default shows millis, so we need to convert to a date + time
  d = new Date Math.floor obj.x
  t = Flotr.Date.format d, '%b %d, %H:%M:%S', 'local'
  " #{t} - #{obj.y} "

# TODO this duplicates the same code on the server, see status.coffee
adjustValue = (value, info) ->
  if info.factor
    value *= info.factor
  if info.scale < 0
    value *= Math.pow 10, -info.scale
  else if info.scale >= 0
    value /= Math.pow 10, info.scale
    # value = value.toFixed info.scale
  value
