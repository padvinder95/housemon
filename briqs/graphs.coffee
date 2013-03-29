exports.info =
  name: 'graphs'
  description: 'Show a graph with historical data'
  menus: [
    title: 'Graphs'
    controller: 'GraphsCtrl'
  ]
  connections:
    feeds:
      'hist': 'redis'
