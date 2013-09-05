Measurement dataflow overview
=============================

This document tries to cover all the important points you need to know as a
driver/briq writer when it comes to the receiving and processing of packet
from remote nodes through to the determination of what the data actually
means.

rf12demo-serial briq
--------------------

When a packet is received from the serial port it is processed by the
rf12demo-serial briq.  This briq reads from a serial port where a JeeNode
is attached running the RF12demo sketch.  It sends two messages:

* `rf12.announce {id:0, buffer: <bytes received>, ...}`

  Here the same object is passed each time. Receivers store information in this object as it is also passed when data arrives.
  If the announcement is in standard format then the first few bytes will be:

        buffer[0] = 64
        buffer[1] = nodeId
        buffer[2] = counter
        buffer[3] = sketchID hi
        buffer[4] = sketchID lo
        buffer[5] = beginning of data

  See http://jeelabs.org/2013/01/15/remote-node-discovery-part-2/ for more details.

  Note you will only receive these packets if your receiver is node 31.

* `rf12.packet {id: <nodeid>, recvid: <receiverid>, group: <group id>, band: <band>, buffer: <bytes received>}, <state for this node>`

  This is also the same object each time, so don't try to store it. The
fields are mostly self-explanitory.  The bytes are as they come from the
rf12demo sketch.  That is, the first byte is the node is, followed by the
rest of the data.

drivers briq
------------

The above messages are picked up by the drivers briq.

* on `rf12.announce` it unpacks the sketch id (bytes 3 and 4) and tries to
  determine the name based on known announcer ids.

* on `rf12.packet` it looks up the driver from the static list
  (nodeMap.rf12nodes) or as determined by the announcer id from a previously
  receive `rf12.announce` packet.

  The packet object is passed as is and the driver should return a hash with the decoded readings. Simply:

        { reading1: <value1>, reading2: <value2>, ... }

  The names of the readings can be whatever you like, the values should be
  integers.  You can optionally set the field `tag` which can be used to
  identify the device this came from in case you're demultiplexing. More on this later.

  This object has two fields added, a `key` and a `timestamp`. The former in
  generated the latter is copied from the packet.  The result is sent as:

        state.store 'readings', {key:"RF12:#{packet.group}:#{packet.id}.#{name}", time: <timestamp>, reading1: <value1>, ...}

  The name can either by determined by the driver by using the 'tag' field,
  otherwise it is the name of the driver. Note this name is used later to
  determine how to decode the readings.

  These readings are then picked up by the status briq after being rebroadcast by the state module.

status briq
-----------

The status briq splits the `key` field back into a location name (e.g.
RF12:1:2) and a driver name (e.g.  roomNode).  Either the location name or
the driver name must exist in `models.locations` or the reading is ignored.
Hence if you're demultiplexing you need to generate a useful value here or
all your readings will vanish.

The driver name is looked up in `models.drivers`, which is defined by the
drivers briq at startup by scanning all the drivers, looking for a
`descriptions` and store the content of that in the `models.drivers` state.

In this briq the name of the reading (the "reading1" above) is looked up in
the driver description and the result is stored as `status`, with all the
fields worked out:

    state.store 'status', {
        key: "#{location.title} - #{description[reading].title}"
        location: <title of location>
        parameter: <title of reading (e.g. Humidity)>
        value: <actual value (floating point)>
        unit: <unit>
        time: <timestamp>
        origin: <location>
        type: <drivername>
        name: <name of reading>
        origval: <originally received value>
        factor: <reading factor>
        scale: <reading scale>
    }

The archiver and the history briqs both work with the status objects rather
than the readings directly, which is why they don't work without the status
briq.

The `models.drivers` and `models.locations` can be filled using statements like:

    state.store 'locations', {key:<key>, ...}

where the rest is the value. The `models.drivers` is done by the drivers
briq, the `models.locations` currently only statically defined by the
nodeMap briq.
