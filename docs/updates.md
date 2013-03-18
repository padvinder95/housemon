# Updates

These notes describe how to update HouseMon to a new release.

For "simple" updates, the suggested method is to simply type:

    cd ~/housemon && git pull

This "pulls" the lates changes from GitHub, and since the "nodemon" process is
presumably watching for file changes, it will detect the changes and relaunch
a fresh version of HouseMon.

There are several gotcha's, however:

* if you didn't start HouseMon with the "nodemon" app, kill and restart manually
* if the change is in the client-side files, and if HouseMon was started in
  "development" mode, then HouseMon will force browser reloads and all is well
* if started in production mode, you still need to manually kill and restart

Note that forced restarts are a bit rough on the server, as this will interrupt
anything it was doing, including writing or modifying files. Sincd Redis is not
restarted, that part is actually ok. Just the node procees itself is affected.

## Major updates

For more substantial updates, there may be more work involved:

* **node.js** - If you need to install a new version of Node.js, then you'll
  have to go through the same steps as you did for initial setup, including
  downloading and possibly even re-compiling it from scratch. On the mac, do:

        brew update && brew upgrade

* **npm** - This is now part of Node.js, so npm updates should normally be done
  in the same way, and at the same time as Node.js itself.

* **modules** - If the npm modules used by HouseMon have to be updated, or if
  new ones need to be installed, stop HouseMon and run this command:

        cd ~/housemon && npm update -g && npm update

* **briqs** - If some briqs have been removed, or have changed in major ways,
  then HouseMon may not start up anymore. In that case, clear the Redis db
  and restart:

        $ redis-cli
        > select 1
        > flushdb
        ^D

  This will lose your current configuration and history, so you will have to
  set things up again on the admin page. A better solution is clearly needed.

See also this issue on GitHub: <https://github.com/jcw/housemon/issues/38>

# Development branch

There is a "develop" branch on GitHub where all the latest features and fixes
are being added. To follow these changes, enter the following command once:

    cd ~/housemon && git branch develop

To restore the release version, enter this instead:

    cd ~/housemon && git branch master

Warning: the development branch changes - *and breaks* - much more frequently!
