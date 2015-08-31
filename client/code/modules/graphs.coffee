# Graphs module definitions

# Data points need to be represented as array in a specific way for Dygraphs.
# The reason is that they have to share the same x-values, so when adding a new
# series, dummy null values may need to be inserted to maintain this invariant.
# Likewise, after removal, quite a bit of work may have to be done to clean up.

labels = ['']
points = []
info = undefined
isRate = undefined

addSeries = (name, values) ->
  if _.indexOf(labels, name) < 0
    labels.push name

    # merge new series into existing points
    next = 0 # next point to adjust
    for i in [0...values.length] by 2
      time = new Date(parseInt values[i+1])
      # add null for intermediate points
      while points[next] and points[next][0] < time
        points[next++].push null
      # if this is a new time, then first insert an empty point for it
      if not points[next] or points[next][0] > time
        points.splice next, 0, [time]
        while points[next].length + 1 < labels.length
          points[next].push null
      # now we can safely append the new value
      points[next++].push adjustValue parseInt(values[i]), info

    # finish any remaining entries
    while next < points.length
      points[next++].push null

removeSeries = (name) ->
  # determine which column to remove, ignore if it's not present
  column = _.indexOf labels, name
  if column > 0
    # remove the label and all its values
    labels.splice column, 1
    for point in points
      point.splice column, 1
    # remove all points consisting only of nulls
    points = _.reject points, (point) ->
      _.every point.slice(1), (v) -> v is null

toggleSeries = (name, values) ->
  if name in labels
    removeSeries name
  else
    addSeries name, values
  # console.log 'ss', labels, (p.length  for p in points)

addOne = (name, time, value) ->
  

module.exports = (ng) ->

  ng.controller 'GraphsCtrl', [
    '$scope','rpc',
    ($scope, rpc) ->

      period = undefined

      graph = new Dygraph 'chart'

      $scope.setGraph = (key) ->
        period = ($scope.hours or 4) * 3600000
        promise = rpc.exec 'host.api', 'rawRange', key, -period, 0
        promise.then (values) ->
          return  unless values

          info = $scope.status.find key
          toggleSeries key, values

          isRate = info.unit in [ 'W', 'km/h' ]

          graph.updateOptions
            file: points
            stepPlot: isRate
            fillGraph: isRate
            includeZero: isRate
            legend: "always"
            labels: labels
            labelsSeparateLines: true
            ylabel: info.unit
            showRangeSelector: true
            connectSeparatedPoints: true

      # TODO open page with fixed choice, for testing convenience only
      $scope.setGraph 'meterkast - Usage'

      $scope.$on 'aset.status', (event, obj, oldObj) ->
        if obj.key is lastKey
          dataPoints.push [ new Date(obj.time), obj.value ]
          # remove any earlier points outside the requested $scope.hours range
          while dataPoints[0][0].getTime() < obj.time - period
            dataPoints.shift()
          graph.updateOptions file: dataPoints

      $scope.hoursChanged = _.debounce ->
        for key in _.clone labels # careful, labels var is changed during loop
          if key isnt ''
            removeSeries key
            $scope.setGraph key
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
