module.exports =

  info:
    name: 'rf12demo'
    description: 'Serial interface for a JeeNode running the RF12demo sketch'
    inputs: [
      name: 'Serial port'
      default: 'usb-AH01A0GD' # TODO: list choices with serialport.list
    ]
    connections:
      packages:
        'serialport': '*'
      results:
        'rf12.announce': 'event'
        'rf12.packet': 'event'
        'rf12.config': 'event'
        'rf12.other': 'event'
    settings:
      initcmds:
        title: 'Initial commands sent on startup'
        default: '?'

  factory: 'rf12demo-serial'
