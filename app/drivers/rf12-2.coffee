module.exports =
  # parameters:
  #   batt:
  #     title: 'Battery status', unit: 'V', scale: 3, min: 0, max: 5

  decode: (bytes, info, push) ->
    batt = bytes[6] * 256 + bytes[5]
    push { batt }
