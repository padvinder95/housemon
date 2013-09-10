# HouseMon 0.8.x

There are no dependencies, other than node 0.10.x:

```
npm install
node .
```

Some stuff is hard-coded (e.g. app/rf12demo/server.coffee).

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
  console.log 'My plugin started'

  plugin.server = (primus) ->
    console.log 'My plugin on the server'

  plugin.client = (primus) ->
    console.log 'My plugin on the client'
```

Once set up, these plugin objects will be available as `app.config.plugin.NAME`.

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
