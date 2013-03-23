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
        # FIXME hardcoded segment number
        segment = 370
        $scope.selection = key
        $scope.results = ''
        archId = keyMap[key]
        request =
          method: 'GET'
          url: "/archive/p#{segment}/p#{segment}-#{archId}.dat"
          responseType: 'arraybuffer'
        $http(request)
          .success (data, status, headers, config) ->
            console.log key, archId, status, typeof data
            $scope.results = decodeArchiveData segment, new Int32Array data
  ]

decodeArchiveData = (segment, array) ->
  result = []
  for i in [0...array.length] by 5
    time = segment + i # TODO wrong value
    cnt = array[i]
    if cnt
      mean = array[i+1]
      min = array[i+2]
      max = array[i+3]
      sdev = array[i+4]
      result.push [time ,cnt, mean, min, max, sdev].join ','
  result.join '\n'
