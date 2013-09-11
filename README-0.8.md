# HouseMon 0.8.x

There are no dependencies other than node 0.10.x:

```
npm install
node .
```

Some stuff is hard-coded, see `app/process/host.coffee`.

*Work-in-progress... what follows are some first developer notes.*

## Plugins

All plugins (Briqs?) are directories in the `./app` folder (flat, no nesting).

If there is a 'client' module, it will be loaded in the browser on connect.
This uses the 'library' field in the plugin detail objects passed to Primus.
No CommonJS support, so 'require' is not (yet?) possible.

If there is a 'host' module, it will be installed in the server as part of the
Primus object creation sequence, just after the HTTP server has been set up.
Each host module gets called with two arguments: `app` (the Connect object) and
`plugin`, which can be filled in to further prepare it for Primus use. Example:

```coffee
module.exports = (app, plugin) ->
  console.log 'My plugin loaded'

  app.on 'setup', ->
    console.log 'All plugins have been loaded'

  app.on 'running', ->
    console.log 'The server has been started'

  plugin.server = (primus) ->
    console.log 'My plugin on the server'
    primus.on 'connection', (spark) ->
      console.log 'My plugin, talking to a client'

  plugin.client = (primus) ->
    console.log 'My plugin on the client'
```

Once set up, these plugin objects will be available as `app.config.plugin.NAME`.

## Startup

Application startup can be tricky, a bit like constructing a house of cards:

* It starts when "`node .`" launches the primus-live package via `index.js`:
    * `supervisor.coffee` sets itself up as a Node.js cluster
    * `preflight.coffee` scans and installs npm & bower packages found in `app`
    * then it launches a worker process running the `worker.coffee` script

* The worker process then:
    * starts watching for changes in the `app` folder
    * sets up a `Connect` type server app
    * defines a live-reload plugin for Primus
    * loads and calls the `app/launch` module, if present
    * scans for host- and client-plugin modules in the `app` folder
    * does `app.emit 'setup'` to signal that everything has been loaded
    * creates the HTTP server and a new Primus object
    * lets Primus initialise all host-side plugins
    * starts the server up, listening on a port (default 3333)
    * does `app.emit "running"` to signal that the server is roaring to go

* The `app/launch` script can be used for the initial app-specific logic:
    * adding more definitions to the `app` object
    * hooking into the `setup` and `running` events

* The host-side plugin code can then do everything else by hooking into the
  `app` events, and Primus connection events.

* The client-side plugin code will be loaded into each client when it connects,
  so this code will be running in a slightly different browser environment.

The general guideline for hooking into events, is to do so as late as possible:

* the `setup` event is the place to add further information to the app registry
* the `running` event is when actual processing activity should be started

## Style Guide

* 2-space indentation, no tabs
* interCapped variable names, not under_lined
* class names Capitalised, constants in ALL_CAPS
* prefer indented if, unless, for over end-of line versions
* lines no longer than 80 characters
* source files preferably under 100 lines
* file names all lower case alhpanumerics, "-" for namespacing
* prefer small functions with good names over extensive comments
* single empty lines where needed, no #####, etc comment dividers
* at most three lines at the top for description, author, and license info
