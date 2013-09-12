ng = angular.module 'myApp'

ng.config ($stateProvider, navbarProvider) ->
  $stateProvider
    .state 'diagram',
      url: '/vdiagram'
      templateUrl: 'vdiagram/view.html'
      controller: 'DiagramCtrl'
  navbarProvider.add '/vdiagram', 'Diagram', 33

ng.controller 'DiagramCtrl', ->
  ded = createDiagramEditor 'vdiagram', 640, 400
  ded.addNode 50, 25, 'Oscillator', ['Frequency','Shape'], ['Waveform']
  ded.addNode 50, 125, 'Oscillator', ['Frequency','Shape'], ['Waveform']
  ded.addNode 250, 75, 'Mixer', ['*Inputs'], ['Waveform']
  ded.addNode 450, 75, 'Player', ['Waveform']
