# Readings module definitions

module.exports = (ng) ->

  ng.controller 'ReadingsCtrl', [
    '$scope',
    ($scope) ->

      $scope.collection 'readings'

      topBotMargin = 22   # pixels
      maxProduced = 5000  # Watt
      maxConsumed = 5000  # Watt
      scaleMinimum = 0    # Watt
      
      # 0 gives sqrt scaling, 30 is a nice value for log scaling
      mapFun = if scaleMinimum >= 1 then Math.log else Math.sqrt
      
      mp = mapFun maxProduced
      mc = mapFun maxConsumed
      sm = mapFun scaleMinimum
      
      canvas = jQuery('#mybar')[0]
      ctx = canvas.getContext '2d'
      w = canvas.width
      h = canvas.height
      scale = (h - 2 * topBotMargin) / ((mp - sm) + (mc - sm))
      
      energyToPixel = (value) ->
        if value > scaleMinimum
          value = Math.min value, maxProduced
          pos = mp - mapFun value
        else if value < -scaleMinimum
          value = Math.min -value, maxConsumed
          pos = mp - sm + mapFun(value) - sm
        else
          pos = mp - sm
        pos * scale + topBotMargin

      drawLine = (colour, value) ->
        pos = energyToPixel value
        ctx.beginPath()
        ctx.strokeStyle = colour
        ctx.lineWidth = 1
        ctx.moveTo 0, pos
        ctx.lineTo w, pos
        ctx.stroke()
              
      drawCircle = (colour, value) ->
        pos = energyToPixel value
        # scaled so max 5000 is about same size as blue circle
        radius = 2.3 * Math.log(2 + Math.abs value)
        radius = 20  if colour is 'blue'
        ctx.beginPath()
        ctx.arc 43, pos, radius, 0, 2 * Math.PI, false
        if colour is 'blue'
          ctx.lineWidth = 3
          ctx.strokeStyle = colour
          ctx.stroke()
        else
          ctx.fillStyle = colour
          ctx.fill()

      drawTicks = ->
        ctx.clearRect 20, 0, w, h
        w = 8
        for i in [-29..29]
          drawLine 'lightgreen', i * 10
        w = 12
        for i in [-29..29]
          drawLine 'orange', i * 100
        w = 20
        for i in [-10..10]
          drawLine 'red', i * 1000
        w = 70
        drawLine 'lightgray', 0
        ctx.moveTo 0, topBotMargin
        ctx.lineTo 0, h-topBotMargin
        ctx.stroke()

      $scope.$on 'set.readings', (event, reading) ->
        if reading.key is 'RF12:868:5:9.homePower'
          produced = reading.p2 / 10
          # ignore small residual readings when the inverter is off
          if produced < 20 and
              $scope.readings.find('RF12:868:5:15.smaRelay')?.acw is 0
            produced = 0
          consumed = (reading.p1 + reading.p3) / 10
          drawTicks()
          drawCircle 'red', -consumed
          drawCircle 'green', produced
          drawCircle 'blue', produced - consumed
  ]

  ng.filter 'cleanup', ->
    (obj) ->
      _.omit obj, 'id', 'key', 'time', '$$hashKey'
