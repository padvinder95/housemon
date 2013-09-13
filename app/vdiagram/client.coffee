ng = angular.module 'myApp'

ng.config ($stateProvider, navbarProvider) ->
  $stateProvider
    .state 'diagram',
      url: '/vdiagram'
      templateUrl: 'vdiagram/view.html'
      controller: 'DiagramCtrl'
  navbarProvider.add '/vdiagram', 'Diagram', 33

ng.controller 'DiagramCtrl', ->
  createDiagramEditor('vdiagram')
    .addNode 50, 50, 'Oscillator 1',
      in: ['Frequency','Timbre','Modulation']
      out: ['Waveform']
    .addNode 50, 180, 'Oscillator 2',
      in: ['Frequency','Shape']
      out: ['Waveform']
    .addNode 275, 100, 'Mixer',
      in: ['#Inputs']
      out: ['Waveform','Load']
    .addNode 480, 100, 'Player',
      in: ['Waveform']
