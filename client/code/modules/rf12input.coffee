###
#
#
#   RF12input client side ng controller
#   Revision: 0.1.0
#   Author: lightbulb -at- laughlinez (dot) com
#           https://github.com/TheDistractor
#   more info at: http://thedistractor.github.io/housemon/rf12input.html
#
#   License: MIT - see http://thedistractor.github.io/housemon/MIT-LICENSE.html
#
###

module.exports = (ng) ->

  ng.controller 'RF12inputCtrl', [
    '$scope','$log','rpc'
    ($scope,$log,rpc) ->
    
    
      #last 20 write events   
      $scope.eventStack = []
    
      #message broadcast by rf12input BRIQ when it hears a client make write.
      $scope.$on 'ss-rf12-write', (event, args...) ->  
        $log.info "incomming write - event:", args...
        #$log.info "args:", args...
        $scope.eventStack.push args[0]
        if $scope.eventStack.length > 20 #we only want to stack 20 messages.
          $scope.eventStack.splice(0,1)
      
      
      #TODO: move these to configuration sub-system
      $scope.writeDefaults =
        band: 868
        group: 136
        node: 31
        header: 0 


      #$log.info "logging active..."

      #setup view defaults      
      $scope.band = $scope.writeDefaults.band
      $scope.group = $scope.writeDefaults.group
      $scope.node = $scope.writeDefaults.node
      $scope.header = $scope.writeDefaults.header
      $scope.data = null
  
      #gui wants us to make a write
      $scope.makeWriteRequest = () ->
        #result = true
        #$log.info "write request start:"
        $scope.writeResult = rpc.exec 'rf12input.Write', $scope.band, $scope.group, $scope.node, $scope.header, $scope.data
        #$log.info "write request end:"
        #return true
      
      #quick helper - do it here incase we want better TZ control in future.
      $scope.toDate = ( ms ) ->
         return (new Date(ms))
      
        
  ]
