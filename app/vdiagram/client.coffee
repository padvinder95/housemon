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
  ded.addNode 50, 50, 'Oscillator 1',
    ['Frequency','Timbre','Modulation'], ['Waveform']
  ded.addNode 50, 180, 'Oscillator 2', ['Frequency','Shape'], ['Waveform']
  ded.addNode 275, 100, 'Mixer', ['*Inputs'], ['Waveform','Load']
  ded.addNode 480, 100, 'Player', ['Waveform']
