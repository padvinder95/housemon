# Roadmap

The development of HouseMon is still in the very early stages. Part of this
comes from the fact that the direction of the whole project is still in flux,
but another important reason is that I'm still learning the ropes of Node.js,
and almost daily seeing new interesting packages and approaches which may
affect the choices for HouseMon.

The current version of HouseMon (0.6.0) is fairly solid, it has been running 
for several weeks without a single hickup, collecting data and showing graphs.
The modularity of Briqs is working out fairly well, although the API of it all
is fairly quirky. Interface drivers for a number of devices have been created
with very little coding effort.

So much for what works. There are also lots of loose ends:

* Right now, the data is only one-way: i.e. dealing with incoming readings.
  The key missing feature is to be able to send out commands as well.

* The dependencies between briqs are not enforced, so you have to know which
  briqs depend on which, or else just try out a couple of things. Not optimal.
  
* Data can be stored in log files (forever), as historical data in Redis (up to
  50 hours), or aggregated in archive files (forever, but stored per hour). But
  it's not all peaches: replaying log files is incomplete, exports are still
  very limited, and archives are not yet updated properly from the Redis data
  in the first hour after startup. Then again: the log files are the core of it
  all, and they *do* contain everything we need, omce the rest is implemented.
  
* The configuration of briqs is not ready, and the home page is just a bit of
  static text for now. The plan is to be able to add graphs and controls to it.
  
* Graphs can only look back over what is currently stored in the history data,
  i.e. at most 50 hours. And there is not yet a way to graph more than a single
  parameter at once. Large graphs are inefficient, because of some umb coding.

Lots and lots of things still left to do, clearly, before this project can be
truly useful and practical. As with any project in such an early stage, there
are bound to be some major re-factorings ahead, as the code evolves and grows.
