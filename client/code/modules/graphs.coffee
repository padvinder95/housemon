# Graphs module definitions

module.exports = (ng) ->

  ng.controller 'GraphsCtrl', [
    '$scope','rpc',
    ($scope, rpc) ->

      selection = {}
      lastKey = undefined
      dataPoints = undefined
      period = undefined

      graph = new Dygraph 'chart'

      $scope.setGraph = (key) ->
        lastKey = undefined # prevent status events from interfering

        selection = {}
        selection[key] = true

        period = ($scope.hours or 1) * 3600000
        promise = rpc.exec 'host.api', 'rawRange', key, -period, 0
        promise.then (values) ->
          return  unless values

          info = $scope.status.find key

          dataPoints = []
          for i in [0...values.length] by 2
            dataPoints.push [
              new Date(parseInt values[i+1])
              adjustValue parseInt(values[i]), info
            ]

          lastKey = key # now we can accept status change events

          graph.updateOptions
            file: dataPoints
            stepPlot: info.unit is 'W'
            legend: "always"
            labels: [ "", info.key ]
            labelsSeparateLines: true
            ylabel: info.unit
            fillGraph: true

      # TODO open page with fixed choice, for testing convenience only
      $scope.setGraph 'meterkast - Usage house'

      # TODO not used yet, this will allow graphing more variables together
      #   not so obvious though, if the units differ: flotr2 has 2 scales max
      #   proper way to do this would be to disable variables for any 3rd unit
      #
      # $scope.selectParam = (key) ->
      #   if selection[key]
      #     delete selection[key]
      #   else
      #     selection[key] = true
      #   redrawGraph()

      $scope.$on 'set.status', (event, obj, oldObj) ->
        if obj.key is lastKey
          dataPoints.push [ new Date(obj.time), obj.value ]
          # remove any earlier points outside the requested $scope.hours range
          while dataPoints[0][0].getTime() < obj.time - period
            dataPoints.shift()
          graph.updateOptions file: dataPoints

      $scope.hoursChanged = _.debounce ->
        $scope.setGraph lastKey
      , 500
  ]

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
