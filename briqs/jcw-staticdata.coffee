exports.info =
  name: 'jcw-staticdata'
  description: 'Static data definitions (temporary)'
  menus: [
    title: 'Data'
  ]
  connections:
    results:
      'locations': 'collection'
  
nodeMap = require './nodeMap'
state = require '../server/state'

exports.factory = class
  
  constructor: ->
    # delete existing locations first
    state.store 'locations', { id: id }  for id of state.models.locations
    # now add all the entries defined in nodeMap
    for k,v of nodeMap.locations
      v.key = k
      state.store 'locations', v
