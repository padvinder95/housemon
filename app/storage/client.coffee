ng = angular.module 'myApp'

# TODO: shouldn't this be a service, or somethin'?
ng.config (primus) ->

  primus.live = (scope, prefix) ->
    table = {}
    primus.write ['live', prefix]
    # FIXME: scope has no place in this code, I'm mixing up stuff here...
    scope.$on "live.#{prefix}", (event, type, value) ->
      switch type
        when 'put'
          table[value.key] = value
        when 'del'
          delete table[value]

    table

