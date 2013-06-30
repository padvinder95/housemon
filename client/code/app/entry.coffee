# This client-side code gets called first by SocketStream and must always exist

# Make 'ss' available to all modules and the browser console
# FIXME looks like window.ss is needed to reconnect properly?
window.ss = ss = require 'socketstream'

ss.server.on 'disconnect', ->
  console.info 'Connection down'

ss.server.on 'reconnect', ->
  console.info 'Connection back up'
  # force full reload to re-establish all model links
  window.location.reload true

# sample console log in the browser:
#   app ready
#   models fetched ["pkg", "local", "process", "briqs", "bobs", "..."]
#   require ["/main", "/home", "/admin", "/data", "/status", "/..."]
#   ng bootstrap
#   app config
#   app run

ss.server.once 'ready', ->
  #jQuery ->
    console.info 'app ready'
    ss.rpc 'host.api', 'fetch', (models) ->
      console.info 'models fetched', _.keys models

      # collect routes from the current list of installed briq objects
      for k,obj of models.bobs
        briq = models.briqs[obj.briq_id] # TODO: generic parent lookup
        routes.push r  for r in briq?.info?.menus or []

      # set up a list of modules which need to be loaded
      paths = ['/main']
      for r in routes
        if r.title
          name = r.title.toLowerCase()
          r.route ?= "/#{name}"
          r.templateUrl ?= "#{name}.html"
          paths.push "/#{name}"

      # make models and routes available via dependency injection
      app.value 'models', models
      app.value 'routes', routes

      console.info 'require', paths
      require(path) app  for path in paths

      console.info 'ng bootstrap'
      angular.bootstrap document, ['app']

# routes which have a title will appear in the main menu
# the order in the menu is the order in the routes array below
# load and route both default to "/title-in-lowercase" if title is set

routes = [
  { title: 'Home', controller: 'HomeCtrl', route: '/' }
  { title: 'Admin', controller: 'AdminCtrl' }
  { title: 'Docs', controller: 'DocsCtrl' , route: '/docs'}
]

app = angular.module 'app', []

app.config [
  '$routeProvider','$locationProvider',
  ($routeProvider, $locationProvider) ->
    console.info 'app config'
    
    for r in routes
      $routeProvider.when r.route, r
    $routeProvider.otherwise
      redirectTo: '/'
       
    $locationProvider.html5Mode true
]

app.run [
  'models','$rootScope','store',
  (models, $rootScope, store) ->
    console.info 'app run'

    # forward all incoming ss-* pubsub events to NG
    ss.event.onAny (args...) ->
      $rootScope.$apply => $rootScope.$broadcast @event, args...

    store.setup models
]

# This service sets up a listener to ss-store events, and creates pseudo-arrays
# in the root scope which track all changes. These changes are also broadcast,
# so that any module can tie into these changes and act whenever they occur.
# Intitial setup generates a set of fake events, as if all rows were new ones.
#
#  - broadcasts row change y on collection x as ('set.x', y, oldY)
#  - for new rows, oldY is null, for deleted rows, y will be null

app.service 'store', [
  '$rootScope','rpc',
  ($rootScope, rpc) ->

    $rootScope.collection = (name) ->
      unless $rootScope[name]
        # create an array and add some object attributes to it
        # this way the extra attributes won't be enumerated
        coll = $rootScope[name] = []
        # map ID's to objects
        coll.byId = {}
        # find object in collection, given its key
        coll.find = (value) -> _.find @, (obj) -> obj.key is value
        # store an object (must have either a key, an id, or both)
        coll.store = (obj) -> rpc.exec 'host.api', 'store', name, obj
      $rootScope[name]
  
    # the server emits ss-store events to update each of the client models
    $rootScope.$on 'ss-store', (event, name, obj) ->
      coll = $rootScope.collection name
      oldObj = coll.byId[obj.id]
      if oldObj
        oldPos = coll.indexOf(oldObj)
      key = obj.key
      if key
        coll.byId[obj.id] = obj
        if oldObj
          coll[oldPos] = obj
        else
          coll.push obj
      else if oldObj
        delete coll[obj.id]
        coll.splice oldPos, 1
        key = oldObj.key
        obj = null
      else
        console.info 'store?', name, obj
        return
      $rootScope.$broadcast "set.#{name}", obj, oldObj
      $rootScope.$broadcast "set.#{name}.#{key}", obj, oldObj
      # $rootScope.$broadcast 'set', name, oldObj
          
    setup: (models) ->
      for name,coll of models
        if name in ['pkg', 'local', 'process']
          $rootScope[name] = coll
        else
          # make sure the collection gets set up, even if it has no data
          $rootScope.collection name
          # emit an ss-store event to get all the collection details right
          $rootScope.$broadcast 'ss-store', name, v  for k,v of coll
]

# Credit to https://github.com/polidore/ss-angular for ss rpc/pubsub wrapping
# Thx also to https://github.com/americanyak/ss-angular-demo for the demo code

app.service 'rpc', [
  '$q','$rootScope',
  ($q, $rootScope) ->

    # call ss.rpc with 'demoRpc.foobar', args..., {callback}
    exec: (args...) ->
      deferred = $q.defer()
      ss.rpc args..., (err, res) ->
        $rootScope.$apply () ->
          return deferred.reject(err)  if err
          deferred.resolve res
      deferred.promise

    # use cache across controllers for client-side caching
    cache: {}
]
