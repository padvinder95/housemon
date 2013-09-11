# HouseMon 0.8.x

There are no dependencies other than node 0.10.x:

```
npm install
node .
```

Some stuff is hard-coded, see `app/process/host.coffee`.

*Work-in-progress... what follows are some early developer notes.*

----

* [Plugins](#plugins)
* [Startup](#startup)
* [Adding Drivers](#adding-drivers)
* [Style Guide](#style-guide)

----

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

Application startup can be tricky, it's a bit like setting up a house of cards:

* It all starts when "`node .`" launches the primus-live package via `index.js`:
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

## Adding Drivers

Drivers are defined as lightweight objects (only simple prototype inheritance).
They can be defined as full plugins in their own folder, but there is also a
quicker way to define them: add a file to the `app/drivers` folder. Example:

```coffee
module.exports = (app) ->
  app.register 'driver.testnode',
    in: 'Buffer'
    out:
      batt:
        title: 'Battery status', unit: 'V', scale: 3, min: 0, max: 5

    decode: (data) ->
      { batt: data.msg.readUInt16LE 5 }
```

The actual work is done by the `decode` function, which is called once for each
incoming message, and which can return zero, one, or more results:

* return a falsey value to indicate that there is no result
* return an object with fields if there is one result
* return an array of objects if there are more results (or 1, or 0)

Drivers can include meta data, describing the expected inputs and outputs, etc:

* **announcer** is information which can be used for automatic node discovery
* **in** describes the type of input data, it should always be `Buffer` for now
* **out** describes each of the possible output field names and types
* for drivers producing multiple output types, `out` can be an array of names
* in this case, there should be a field with further details for each each type
* drivers can maintain state from one invocation to the next, by using _@blah_

Some more conventions:

* the incoming data is in the field `msg`
* in the case of RF12 packets, this field will contain a Buffer object
* of the result has a `tag` field, that will be added to the result
* the type of result object(s) will always be set to the name of the driver
* drivers should register themselves as `driver.NAME` or `driver.SUB-NAME`
* driver names (and source file names in general) should be in lowercase

A driver source file can register more than one driver. The list of all
registered drivers is available as `app.registry.drivers`.

The mapping from RF12 group + node ID's is done with `nodemap` registry entries:

```coffee
app.register 'nodemap.rf12-868:42:2', 'testnode'
```

Using the nodemap entries, each incoming packet will be dispatched to the proper
driver, which is created on-the-fly as needed.

Nodemap registration needs to be done before the app enters the `running` state.

## Style Guide

* 2-space indentation, no tabs
* interCapped variable names, not under_lined
* class names Capitalised, constants in ALL_CAPS
* prefer indented if, unless, for over end-of line versions
* lines no longer than 80 characters
* source files preferably under 100 lines
* file names all lower case alphanumerics, "-" for namespacing and versioning
* prefer small functions with good names over extensive comments
* single empty lines where needed, no #####, etc comment dividers
* at most three lines at the top for description, author, and license info
