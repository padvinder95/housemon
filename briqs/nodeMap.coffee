# Static node map and other data. This information is temporary, until a real
# admin/config interface is implemented on the client side. The information in
# here reflects the settings used at JeeLabs, but is also used by the "replay"
# briq, which currently works off one of the JeeLabs log files.
#
# This file is not treated as briq because it does not export an 'info' entry.
#
# To add your own settings: do *NOT* edit this file, but create a new one next
# to it called "nodeMap-local.coffee". For example, if you use group 212:
#
#   exports.rf12nodes = 
#     212:
#       1: 'roomNode'
#       2: ...etc
#
# The settings in the local file will be merged (and can override) the settings
# in this file. If you override settings, the "replay" briq may no longer work.

fs = require 'fs'
_ = require 'underscore'

# this is still used for parsing logs which do not include announcer packets
# TODO: needs to be time-dependent, since the config can change over time
exports.rf12nodes =
  5:
    2: 'roomNode'
    3: 'radioBlip'
    4: 'roomNode'
    5: 'roomNode'
    6: 'roomNode'
    9: 'homePower'
    10: 'roomNode'
    11: 'roomNode'
    12: 'roomNode'
    13: 'roomNode'
    14: 'otRelay'
    15: 'smaRelay'
    18: 'p1scanner'
    19: 'ookRelay'
    20: 'slowLogger'
    23: 'roomNode'
    24: 'roomNode'
  # included for the DIJN LDR example
  100:
    1: 'lightNode'

# devices are mapped to RF12 configs, since that is not present in log files
# TODO: same time-dependent comment as above, this mapping is not fixed
# this section is only used by the 'rf12-replay' briq
exports.rf12devices =
  'usb-A40117UK':
    recvid: 1
    group: 5
    band: 868

# the default is used by the "reprocess" briq when no other info is available
exports.rf12default =
    recvid: 1
    group: 5
    band: 868

# static data, used for local testing and for replay of the JeeLabs data
# these map incoming sensor identifiers to locations in the house (in Dutch)
exports.locations =
  'RF12:5:2': title: 'boekenkast JC'
  #'RF12:5:3': title: 'buro JC'
  'RF12:5:4': title: 'washok'
  'RF12:5:5': title: 'woonkamer'
  'RF12:5:6': title: 'hal vloer'
  'RF12:5:9': title: 'meterkast'
  'RF12:5:10': title: 'hal voor'
  'RF12:5:11': title: 'logeerkamer'
  'RF12:5:12': title: 'boekenkast L'
  'RF12:5:13': title: 'raam halfhoog'
  'RF12:5:14': title: 'zolderkamer'
  'RF12:5:15': title: 'washok'
  'RF12:5:18': title: 'meterkast'
  #'RF12:5:19': title: 'kantoor'
  'RF12:5:20': title: 'labtafel'
  'RF12:5:23': title: 'gang boven'
  'RF12:5:24': title: 'zolderkamer'

  'RF12:100:1': title: 'test location'

  'BATT-0': title: 'buro JC'
  'BATT-1': title: 'coin cell test'
  'BATT-2': title: 'penlight test'
  'DCF77': title: 'radioklok'
  'KS300': title: 'weerstation'
  'S300-1': title: 'vlonder'
  'S300-2': title: 'balkon'
  'S300-3': title: 'badkamer'
  'EMX-2': title: 'labtafel'

# TODO need a way to prevent local extension/alteration, for the replay briq
localPath = "#{__dirname}/nodeMap-local.coffee"
if fs.existsSync localPath
  console.info 'extending nodeMap with', localPath
  _.extend module.exports, require localPath
