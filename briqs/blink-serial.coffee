exports.info =
  name: 'jcw-blink'
  description: 'Connect to a JeeNode with a Blink Plug'
  inputs: [
    name: 'Serial port'
    default: 'usb-A40115A2' # TODO: list choices with serialport.list
  ]
  menus: [
    title: 'Blink'
    controller: 'BlinkCtrl'
  ]
  connections:
    results:
      'readings': 'collection'

serialport = require 'serialport'
state = require '../server/state'
_ = require 'underscore'

exports.factory = class extends serialport.SerialPort
  
  constructor: (device) ->
    # TODO expand platform-specific shorthands, not just Mac
    device = device.replace /^usb-/, '/dev/tty.usbserial-'
    
    # construct the serial port object
    super device,
      baudrate: 57600
      parser: serialport.parsers.readline '\r\n'

    info = key: 'blink', b1: false, b2: false, l1: false, l2: false

    @on 'data', (data) ->
      switch data
        when '-1' then info.b1 = false
        when '+1' then info.b1 = true
        when '-2' then info.b2 = false
        when '+2' then info.b2 = true
      state.store 'readings', _.extend {}, info

    adjustLeds = (obj) =>
      info = obj
      @write if info.l1 then 'A' else 'a'
      @write if info.l2 then 'B' else 'b'

    # FIXME without the delay, MacOSX will kernel panic (reliably!!!)
    #   maybe the FTDI driver can't handle output immediately after opening?
    setTimeout =>
      state.on 'set.readings', (obj, oldObj) ->
        if obj?.key is 'blink'
          adjustLeds obj
    , 1000
          
  destroy: -> @close()
