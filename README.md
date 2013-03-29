# HouseMon

Real-time home monitoring and automation.

More info at <http://jeelabs.org/tag/housemon/>.

# Installation

Install [Node.js](http://nodejs.org) and [redis](http://redis.io), then:

    $ git clone https://github.com/jcw/housemon.git
    $ cd housemon
    $ npm install
    
Make sure Redis is running (this app uses database #1, see `local.json`):

    $ redis-server &

Then launch the app as a Node.js web server:

    $ npm start

Now browse to <http://localhost:3333/> (this can be changed in `local.json`).

# Documentation

If you want to start exploring the (early) features of HouseMon, keep these  
points in mind and check <http://jeelabs.org/tag/housemon/> for the latest news:

* the "logger" triggers on "incoming" events, as emitted by the "rf12demo" briq
* the "Readings" page needs drivers and mappings from node ID to that driver
* the "Status" page also needs mappings from node ID's to named locations
* the "archiver" and "history" briqs use status changes, so get that going first
* the "Graphs" page only works off history data, and does not yet auto-update

There is some documentation in the `docs/` folder, but things *do* change fast!

# Seed use

To use this project as starting point for a fresh SocketStream project:

* clone this project, then install all the required packages as described above
* remove everything from the `briqs/` directory, except for `sandbox.coffee`
* the `drivers/` directory can also be removed, since it's HouseMon-specific
* change project name, author, version, etc. in `package.json` and `local.json`

# License

[MIT](http://opensource.org/licenses/MIT)
