# Admin module definitions

# FIXME: need better way to store briqs and installed items, the current
#   approach requires extremely much "data navigation" code and logic :(
# would much better to load rows as instances with extra behavior

# A "briq" is a module which can be installed in the application.
# Doing so creates a "briq object", or "bob", which does the real work.
#
# briqs:
#   id = unique id
#   key = filename
#   info: object from exports, i.e. description, inputs, etc
#
# bobs:
#   id = unique id
#   key = briqname:and:args
#   briq_id: parent briq
#   more... config settings for this installed instance?

module.exports = (ng) ->
  # lightbulb - added in $log for debug helper
  ng.controller 'AdminCtrl', [
    '$scope','$log', 'rpc'
    ($scope,$log, rpc) ->

      $scope.collection 'bobs'

      briqAndBob = (briq, bob) ->
        # if briq no longer exists, make sure we can still delete this object
        briq = info: {}  if not briq and bob
        $scope.briq = briq
        $scope.bob = bob
        if briq?.info?.connections?
          $scope.feeds = briq.info.connections.feeds
          $scope.results = briq.info.connections.results
        else
          $scope.feeds = $scope.results = null

        # and make a nice description if we are supplied markdown
        $scope.prepareBriqDescription()

      
      $scope.selectBriq = (obj) ->
        # if there are no args, it may already have been installed
        if bob = $scope.bobs?.find obj.info.name
          $scope.selectBob bob
        else
          briqAndBob obj
          # TODO candidate for a Briq method
          for input in obj.info.inputs or []
            input.value = null
      
      $scope.createBob = ->
        # TODO candidate for a Briq method
        keyList = [$scope.briq.info.name]
        for input in $scope.briq.info.inputs or []
          keyList.push input.value?.keys or input.value or input.default
          #$log.info "keyList is now:" + keyList
        key = keyList.join(':')

        $scope.bobs.store
          briq_id: $scope.briq.id
          key: key

      $scope.selectBob = (obj) ->
        briqAndBob $scope.briqs.byId[obj?.briq_id], obj

        # TODO candidate for a Briq method
        keys = obj.key.split(':').slice 1
        for input in $scope.briq?.info.inputs or []
          input.value = keys.shift()

      $scope.removeBob = ->
        $scope.bobs.store _.omit $scope.bob, 'key'
        briqAndBob null

      $scope.showAll = ->
        briqAndBob null

      # lightbulb - removed in favour of a batch submission of all settings in one go before inited() called.
      #$scope.changed = _.debounce ->
      #  $scope.bobs.store $scope.bob
      #, 500

      
      # lightbulb - save changed settings in the bob on the server in one go.
      $scope.updateBriqSettings = ->
        $scope.bobs.store $scope.bob

       
      # lightbulb - convert our descriptionHtml (markdown) to html fragment with identification wrapper .markdownContainer
      $scope.prepareBriqDescription = () ->
        if $scope.briq
          $scope.briq.info["descriptionFull"] = rpc.exec 'admin.MarkdowntoHtml', $scope.briq.info.descriptionHtml
      
      
      # lightbulb - shall we enable the debug info panel-set
      $scope.showDebug = true #toggle to false to hide panel 
      
      # lightbulb - allow selective show of bobInfo for debuging
      $scope.showBobInfo = false
      $scope.toggleBobInfo = ( toggle ) ->
        if toggle?
          $scope.showBobInfo = toggle
        else
          $scope.showBobInfo = !$scope.showBobInfo 
        

        
      
  ]
