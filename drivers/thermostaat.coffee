module.exports =

  announcer: 26

  descriptions:
    setpoint:
      title: 'Temperature setpoint'
      unit: '°C'
      scale: 1
      min: 85
      max: 240
      
  feed: 'rf12.packet'
  
  decode: (raw, cb) ->
    cb
      setpoint: raw[2] #0 is sender id, 1 is message's nodeid that is in there as an extra check