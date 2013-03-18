exports.info =
  name: 'sysinfo'
  description: 'Display some system information'
  menus: [
    title: 'SysInfo'
    controller: 'SysInfoCtrl'
  ]
  rpcs: ['sysInfo']

{exec} = require 'child_process'

exports.sysInfo = (cb) ->

  exec 'uptime', (err, up, serr) ->
    throw err  if err
    exec 'df -H', (err, df, serr) ->
      throw err  if err
      exec 'ps xl', (err, ps, serr) ->
        throw err  if err
        cb null,
          up: up
          df: df
          ps: ps
