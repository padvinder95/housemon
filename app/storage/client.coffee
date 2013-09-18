ng = angular.module 'myApp'

# TODO: shouldn't this be a service, or somethin'?
ng.config (primus) ->

  primus.live = (scope, prefix, adjust) ->
    table = []
    primus.write ['live', prefix]
    
    # FIXME: scope has no place in this code, I'm mixing up stuff here...
    scope.$on "live.#{prefix}", (event, type, value) ->
      switch type
        when 'put'
          key = value.key
        when 'del'
          key = value
          value = null
        else
          return

      adjust? value  if value?

      for row, index in table 
        if row.key is key
          if value?
            table[index] = value
          else
            table.splice index, 1
          return

      table.push value

    table

