ng = angular.module 'myApp'

ng.config ($stateProvider, navbarProvider) ->
  $stateProvider
    .state 'diagram',
      url: '/vdiagram'
      templateUrl: 'vdiagram/view.html'
      controller: 'DiagramCtrl'
  navbarProvider.add '/vdiagram', 'Diagram', 34

ng.controller 'DiagramCtrl', ->
  diagram = createDiagramEditor('vdiagram')
    .addNode
      name: 'Oscillator'
      x: 50
      y: 50
      pads:
        'frequency': {}
        'timbre': {}
        'modulation': {}
        'waveform':
          wires:
            3: ['inmix']
    .addNode
      id: 2
      name: 'Oscillator'
      x: 50
      y: 180
      pads:
        'frequency': {}
        'shape': {}
        'waveform':
          wires:
            3: ['inmix']
    .addNode
      id: 3
      name: 'Mixer'
      x: 275
      y: 100
      pads:
        'inmix': {}
        'waveform':
          wires:
            4: ['waveform']
    .addNode
      id: 4
      name: 'Player'
      pads:
        'waveform': {}
    .wireItUp()
    
  diagram.onAddWire = (from, to) ->
    console.log 'added', from.node.name, from.name, '>', to.node.name, to.name

  diagram.onRemoveWire = (from, to) ->
    console.log 'removed', from.node.name, from.name, '>', to.node.name, to.name
    
  # setTimeout ->
  #   diagram.removeNode 3
  # , 3000
