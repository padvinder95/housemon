# Sandbox module definitions

module.exports = (ng) ->

  ng.controller 'ExportCtrl', [
    '$scope','$http',
    ($scope, $http) ->

      $scope.start = 3 # default is to ask for last 3 days of data
      keyMap = {} # will contain a map from parameter names to acrhive id's

      $http.get('/archive/index.json')
        .success (data, status, headers, config) ->
          keyMap = data  if status is 200

      $scope.setSelection = (key) ->
        $scope.selection = key
        $scope.results = ''
        segment = 370 # FIXME hardcoded segment number

        archId = keyMap[key]
        if archId
          request =
            method: 'GET'
            url: "/archive/p#{segment}/p#{segment}-#{archId}.dat"
            responseType: 'arraybuffer'
          # fetch the raw data file from the server
          $http(request)
            .success (data, status, headers, config) ->
              console.log key, archId, status, data.byteLength
              if status is 200
                $scope.results = decodeArchiveData 1024 * segment, data
  ]

# convert the rav data to a list of CSV values
decodeArchiveData = (hours, data) ->
  result = []
  array = new Int32Array data
  for i in [0...array.length] by 5
    cnt = array[i]
    if cnt
      mean = array[i+1]
      min = array[i+2]
      max = array[i+3]
      sdev = array[i+4]
      time = exportDate hours
      result.push [time ,cnt, mean, min, max, sdev].join ','
    hours += 1
  result.join '\n'

# the time is exported as a 10-digit integer: YYYYMMDDHH
exportDate = (hours) ->
  date = new Date(hours * 3600000)
  y = date.getUTCFullYear()
  m = date.getUTCMonth() + 1
  d = date.getUTCDate()
  h = date.getUTCHours()
  ((y * 100 + m) * 100 + d) * 100 + h

