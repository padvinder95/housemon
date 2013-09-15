# Diagram Editor built on top of Raphael.js
# -jcw, 2013-09-15
#
# inspired by https://github.com/ryanwmoore/JsDataFlowEditor
# which was forked from https://github.com/daeken/JsDataFlowEditor

omit = (array, item) ->
  i = array.indexOf item
  array.splice i, 1  if i >= 0

window.createDiagramEditor = (domid) ->
  paper = Raphael domid

  addWire = (from, to, onRemoved) ->
    # Don't create duplicate connections between pads
    for wid in from.wireIds
      wire = paper.getById wid
      if wire.data('from') is from and wire.data('to') is to
        return

    # Add to the output wire list, if not yet present
    toNodeId = to.node.id
    from.wires ?= {}
    wires = from.wires[toNodeId] ?= []
    wires.push to.name  unless to.name in wires

    # Create the path, and associate it with both pads for future redrawing
    wire = paper.path().toBack()
      .attr
        stroke: 'darkblue', 'stroke-width': 3
        path: generatePath(from.eltId, to.eltId)
      .data
        from: from, to: to

    wid = wire.id
    from.wireIds.push wid
    to.wireIds.push wid

    wire.dblclick (e) ->
      removeWire wid
      onRemoved wid

    wire

  removeWire = (wid) ->
    wire = paper.getById wid
    from = wire.data 'from'
    omit from.wireIds, wid
    to = wire.data 'to'
    omit to.wireIds, wid
    toNodeId = to.node.id
    omit from.wires[toNodeId], to.name
    delete from.wires[toNodeId]  unless from.wires[toNodeId].length
    delete from.wires  unless Object.keys(from.wires).length
    wire.remove()

  # Magnetic line direction, adapted from http://raphaeljs.com/graffle.{html,js}
  generatePath = (id1, id2) ->
    obj1 = paper.getById id1
    obj2 = paper.getById id2
    bb1 = obj1.getBBox()
    bb2 = obj2.getBBox()
    p = [
      { x: bb1.x + bb1.width / 2, y: bb1.y - 1              }
      { x: bb1.x + bb1.width / 2, y: bb1.y + bb1.height + 1 }
      { x: bb1.x - 1,             y: bb1.y + bb1.height / 2 }
      { x: bb1.x + bb1.width + 1, y: bb1.y + bb1.height / 2 }
      { x: bb2.x + bb2.width / 2, y: bb2.y - 1              }
      { x: bb2.x + bb2.width / 2, y: bb2.y + bb2.height + 1 }
      { x: bb2.x - 1,             y: bb2.y + bb2.height / 2 }
      { x: bb2.x + bb2.width + 1, y: bb2.y + bb2.height / 2 }
    ]
    d = {}
    dis = []
    for i in [0..3]
      for j in [4..7]
        dx = Math.abs(p[i].x - p[j].x)
        dy = Math.abs(p[i].y - p[j].y)
        if (i is j - 4) or
            (((i isnt 3 and j isnt 6) or
             p[i].x < p[j].x) and ((i isnt 2 and j isnt 7) or
              p[i].x > p[j].x) and ((i isnt 0 and j isnt 5) or
               p[i].y > p[j].y) and ((i isnt 1 and j isnt 4) or
                p[i].y < p[j].y))
          dis.push dx + dy
          d[dis[dis.length - 1]] = [i, j]
    if dis.length
      res = d[Math.min dis...]
    else
      res = [0, 4]
    x1 = p[res[0]].x
    y1 = p[res[0]].y
    x4 = p[res[1]].x
    y4 = p[res[1]].y
    dx = Math.max(Math.abs(x1 - x4) / 2, 10)
    dy = Math.max(Math.abs(y1 - y4) / 2, 10)
    x2 = [x1, x1, x1 - dx, x1 + dx][res[0]].toFixed(3)
    y2 = [y1 - dy, y1 + dy, y1, y1][res[0]].toFixed(3)
    x3 = [0, 0, 0, 0, x4, x4, x4 - dx, x4 + dx][res[1]].toFixed(3)
    y3 = [0, 0, 0, 0, y1 + dy, y1 - dy, y4, y4][res[1]].toFixed(3)
    [
      'M', x1.toFixed(3), y1.toFixed(3)
      'C', x2, y2, x3, y3, x4.toFixed(3), y4.toFixed(3)
    ]

  nodes: {}   # all nodes in this diagram, mapped from their unique id
  groups: {}  # the set of Raphael elements representing a node on-screen

  addNode: (node) ->
    context = @ # FIXME: should use events, see makeConnectable/end/addWire
    {id,name,x,y,pads} = node
    @nodes[id] = node
    group = @groups[id] = paper.set()

    circles = [] # will add this to group after making the rest draggable
    height = 0
    layout =
      in: { elements: [], count: 0, width: 0 }
      out: { elements: [], count: 0, width: 0 }

    makeDraggable = (set) ->
      cx = cy = null

      start = ->
        cx = cy = 0
        set.toFront()
        
      move = (dx, dy, x, y) ->
        set.translate dx - cx, dy - cy
        cx = dx
        cy = dy
        redrawWires()

      redrawWires = ->
        for padName, pad of pads
          for wid in pad.wireIds ? []
            wire = paper.getById wid
            wire.attr path: generatePath wire.data('from').eltId,
                                          wire.data('to').eltId

      set.drag move, start, null, rect, rect

    makeConnectable = (elt, pad) ->
      cursor = line = null
      elt.data 'pad', pad

      start = (x, y, e) ->
        # if not point.multi and point.connections.length
        #   anchor = point.connections[0]
        #   point.removeTo anchor
        cursor = paper.circle e.offsetX, e.offsetY, 3
        cursor.toFront().attr stroke: 'red', fill: 'red'
        line = paper.path()

      move = (dx, dy) ->
        cursor.transform ['T', dx, dy]
        line.attr
          stroke: 'red', 'stroke-width': 3
          path: generatePath elt.id, cursor.id

      end = (e) ->
        cursor.remove()
        line.remove()
        toElt = paper.getElementByPoint e.x, e.y
        toPad = toElt?.data 'pad'
        if toPad and pad.dir isnt toPad.dir and pad.node isnt toPad.node
          if pad.dir is 'in'
            [pad,toPad] = [ toPad, pad ] # exchange the two pads
          wire = addWire pad, toPad, ->
            context.onRemoveWire? pad, toPad
          if wire
            context.onAddWire? pad, toPad

      elt.drag move, start, end

    # Create Raphael elements for all the parts of this node
    for padName, pad of pads
      pad.node = node
      pad.name = padName
      pad.dir = if pad.wires then 'out' else 'in'
      pad.multi = true  if pad.wires # outputs can always multi-connect

      label = paper.text(x, y, padName).attr 'font-size': 12
      group.push label

      circle = paper.circle(x, y, 7.5).attr fill: 'white'
      circles.push circle
      makeConnectable circle, pad

      pad.eltId = circle.id
      pad.wireIds = []

      bbox = label.getBBox()
      height = bbox.height
      width = bbox.width

      dir = if pad.wires then 'out' else 'in'
      e = layout[dir]
      e.elements.push { label, width, circle }
      e.count += 1
      e.width = bbox.width  if bbox.width > e.width

    # The name shown at the top of the node
    title = paper.text x, y, name
    title.attr 'font-size': 16, 'font-weight': 'bold'
    bbox = title.getBBox()

    # Total dimensions, now that all the pieces are known
    count = Math.max layout.in.count, layout.out.count
    nHeight = 8 + bbox.height + count * (height + 5)
    nWidth = 60 + Math.max(50, bbox.width, layout.in.width + layout.out.width)
    
    # The actual node rectangle and separator line
    rect = paper.rect x, y, nWidth, nHeight, 6
    rect.attr fill: '#eef', 'fill-opacity': 0.9
    sep = paper.path ['M', x, y + bbox.height + 2, 'l', nWidth, 0]
    sep.attr 'stroke-width', 0.25

    # Move all the parts to their proper coordinates
    title.translate nWidth / 2, bbox.height / 2 + 1.5
    for dir, column of layout
      pos = 14 + bbox.height + (count - column.count) / 2 * (height + 5)
      column.elements.forEach (e) ->
        switch dir
          when 'in'
            e.circle.translate 12, pos
            e.label.translate 22 + e.width / 2, pos
          when 'out'
            e.circle.translate nWidth - 12, pos
            e.label.translate nWidth - 22 - e.width / 2, pos
        pos += height + 5

    # Insert the rectangle, separator line, and title at the front
    group.splice 0, 0, rect.toBack(), sep, title
    makeDraggable group
    group.push circles... # these too get dragged, but they can't start one
    @

  removeNode: (id) ->
    for padName, pad of @nodes[id]?.pads ? {}
      for wid in pad.wireIds.slice() # using a copy because of self-deletion
        removeWire wid
    @groups[id]?.forEach (elt) ->
      elt.remove()
    delete @groups[id]
    delete @nodes[id]
    @

  wireItUp: ->
    context = @
    for id, node of @nodes
      for padName, pad of node.pads
        for toNodeId, toPadNames of pad.wires ? []
          toInfo = @nodes[toNodeId]
          for to in toPadNames
            toPad = toInfo.pads[to]
            do (pad, toPad) ->
              addWire pad, toPad, ->
                context.onRemoveWire? pad, toPad
    @

  # onAddWire: (from, to) ->
  # onRemoveWire: (from, to) ->
