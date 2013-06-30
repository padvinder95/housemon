# docs module definitions

module.exports = (ng) ->

  ng.controller 'DocsCtrl', [
    '$scope','$log','rpc','$routeParams','$location'
    ($scope,$log,rpc,$routeParams,$location) ->
    
        $scope.docID = null
        
        $scope.sortOrder = '-date'
        $scope.docs = {}
            
        $scope.selectDoc = (doc) ->
          #$log.info "docs is: #{JSON.stringify(doc)}" 
          $scope.docfile = rpc.exec 'docs.get', doc
          
        # call our rpc, but its only a promise!        
        $scope.getDocs = () ->
          $scope.docs = rpc.exec 'docs.list', '.md'
        
        # simplest way to simulate deeplink.
        $scope.$watch 'docs' , (newValue,oldValue, scope) ->
          #our rpc has been fulfulled so drive page from inside controller here.
          $scope.docId = $location.hash() #$routeParams.docId
          angular.forEach newValue, (doc,key) ->
            #$log.info doc
            if doc.name == $scope.docId
              $scope.selectDoc doc

          
        #fill our docs from server              
        $scope.getDocs()
  

  ]
