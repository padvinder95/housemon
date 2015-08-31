###
#   BRIQ: rf12demo-readwrite
#   Version: 0.1.1
#   Author: lightbulb -at- laughlinez (dot) com
#           https://github.com/TheDistractor
#   more info at: http://thedistractor.github.io/housemon/rf12demo-readwrite.html
#
#   License: MIT - see http://thedistractor.github.io/housemon/MIT-LICENSE.html
#   
#   About:
#   Encapsulates read/write of RF12Demo.10+ sketch
#
#   Updated: 0.1.1 - supports basic debug 
#                  - %B %b reversed - see notes
#                  - small tidyup
###

module.exports =

  info:
    name: 'rf12demo-readwrite-bak'
    description: 'Read/Write Serial interface for a device (e.g JeeNode) running a RF12demo.10+ compatible sketches.'
    descriptionHtml: 'Read/Write interface for <b>RF12Demo.10+</b> compatible devices.<br/>For JNu please check/amend baud rate.<br/>Additional settings are available once installed.<br/>For more information click the [about] link above.'
    author: 'lightbulb'
    authorUrl: 'http://thedistractor.github.io/'
    briqUrl: '/docs/#briq-rf12demo-readwrite.md'
    version: '0.1.1'
    inputs: [
      name: 'Serial port'
      default: 'usb-AH01A0GD' # TODO: list choices with serialport.list
    ,
      name: 'Baud Rate'
      default: 57600
    ,
      name: 'Shell Version'
      default: null #supply a fixed version (don't go using version cmd which can cause loop on some CLI's)
    ]
    packages:
      'serialport': '*'
    connections:
      results:
        'rf12.announce': 'event'
        'rf12.packet': 'event'
        'rf12.config': 'event'
        'rf12.other': 'event'
        'rf12.sendcomplete':'event'
        'rf12.version':'event'
        'rf12.write': 'event'
        'rf12.processWriteQ':'event'
    settings:
      initcmds:
        title: 'Initial commands sent on startup'
      writemasks:
        title: 'write mask(s) [see documentation link above]'
        default: null
      commands:
        title: 'Add/Override default CLI commands'
        default: null #'{"version":"v","config":"?"}' 
        
  factory: 'rf12demo-readwrite'
