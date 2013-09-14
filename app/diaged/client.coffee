# adapted from https://github.com/ryanwmoore/JsDataFlowEditor
# which was forked from https://github.com/daeken/JsDataFlowEditor
# looks like the bezier code came from http://raphaeljs.com/graffle.{html,js}

window.createDiagramEditor = (domid, width, height) ->
  anchor = selectedNode = null
  paper = Raphael domid, width, height

  allowConnection = (point) ->

    start = (x, y, e) ->
      if not point.multi and point.connections.length
        anchor = point.connections[0]
        point.removeTo anchor
      else
        anchor = point

      @cursor = paper.circle(e.offsetX, e.offsetY, 3).toFront()
      @line = addConnection anchor.circle, @cursor, 'white', 'black|3'

    move = (dx, dy) ->
      @cursor.transform ['T', dx, dy]
      addConnection @line.from, @line.to, @line

    end = ->
      @cursor.remove()
      removeConnection @line

    point.circle.drag move, start, end

    point.circle.mouseup (e) ->
      unless point.dir is anchor.dir or point.parent is anchor.parent
        anchor.connectTo point

  addConnection = (obj1, obj2, line, bg, removeHook) ->
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
    path = [
      'M', x1.toFixed(3), y1.toFixed(3)
      'C', x2, y2, x3, y3, x4.toFixed(3), y4.toFixed(3)
    ]
    if line and line.line
      line.bg?.attr path: path
      line.line.attr path: path
    else
      color = (if typeof line is 'string' then line else 'black')
      lineElem = paper.path(path)
      bgElem = (if (bg and bg.split) then paper.path(path) else null)
      if removeHook?
        dblclick = (e) ->
          (e.originalEvent or e).preventDefault()
          removeHook()
          lineElem.remove()
          bgElem?.remove()
        lineElem.dblclick dblclick
        bgElem?.dblclick dblclick
        
      line: lineElem.toBack().attr
        stroke: color
        fill: 'none'
      bg: bg?.split and bgElem.toBack().attr
        stroke: bg.split('|')[0]
        fill: 'none'
        'stroke-width': bg.split('|')[1] or 3
      from: obj1
      to: obj2

  removeConnection = (connection) ->
    connection.line?.remove()
    connection.bg?.remove()

  class Node
    constructor: (x, y, name, conns) ->
      @group = paper.set()
      @pads = []

      suppressSelect = false
      inputs = conns.in
      outputs = conns.out

      for input in inputs ? []
        @addPoint input, 'in', input[0] is '#'
      for output in outputs ? []
        @addPoint output, 'out'
      
      cx = cy = null

      start = ->
        cx = cy = 0
        
      move = (dx, dy) =>
        @group.translate dx - cx, dy - cy
        cx = dx
        cy = dy
        suppressSelect = true
        @group.toFront()
        p.fixConnections() for p in @pads
        paper.safari()

      height = 0
      info =
        in: { elements: [], count: 0, width: 0 }
        out: { elements: [], count: 0, width: 0 }

      # Create Raphael elements for all the parts of this node
      for p in @pads
        label = p.label = paper.text x, y, p.label
        label.attr fill: 'black', 'font-size': 12
        circle = p.circle = paper.circle x, y, 7.5
        circle.attr stroke: 'black', fill: 'white'
        bbox = label.getBBox()
        height = bbox.height
        width = bbox.width

        e = info[p.dir]
        e.elements.push { label, width, circle }
        e.count += 1
        e.width = bbox.width  if bbox.width > e.width

        @group.push label, circle.toFront()
        allowConnection p

      # The name shown at the top of the node
      title = paper.text(x, y, name)
      title.attr fill: 'black', 'font-size': 16, 'font-weight': 'bold'
      bbox = title.getBBox()

      # Total dimensions, now that all the pieces are known
      count = Math.max info.in.count, info.out.count
      nHeight = 8 + bbox.height + count * (height + 5)
      nWidth = 60 + Math.max(50, bbox.width, info.in.width + info.out.width)
      
      # The actual node rectangle and separator line
      rect = paper.rect(x, y, nWidth, nHeight, 6)
      rect.attr fill: '#eef', 'fill-opacity': 0.9
      line = paper.path ['M', x, y + bbox.height + 2, 'l', nWidth, 0]
      line.attr 'stroke-width', 0.25

      # Insert the rectangle, separator line, and title at the front
      @group.splice 0, 0, rect.toBack(), line, title

      # Move all the parts to their proper coordinates
      title.translate nWidth / 2, bbox.height / 2 + 1.5
      for dir, column of info
        pos = 14 + bbox.height + (count - column.count) / 2 * (height + 5)
        column.elements.forEach (e) ->
          switch dir
            when 'in'
              e.circle.translate 12, pos
              e.label.translate 22 + e.width / 2, pos
            when 'out'
              e.circle.translate nWidth - 12, pos
              e.label.translate nWidth - 22 - e.width / 2, pos
          e.label.drag move, start, null, rect, rect
          pos += height + 5

      # Node selection and deselection
      rect.click =>
        if suppressSelect is true
          suppressSelect = false
        else if @ is selectedNode
          @blur()
        else
          @focus()

      # Dragging nodes around (see also the label drag calls above)
      title.drag move, start, null, rect, rect
      rect.drag move, start

    remove: ->
      @blur()  if @ is selectedNode
      @group.remove()
      p.remove()  for p in @pads

    addPoint: (label, dir, multi) ->
      @pads.push new Pad(@, label, dir, multi)
    
    focus: ->
      selectedNode?.blur()  unless @ is selectedNode
      selectedNode = @
      @group.toFront()
      rect = @group[0]
      rect.attr 'stroke-width', 3

    blur: ->
      selectedNode = null
      rect = @group[0]
      rect.attr 'stroke-width', 1

  class Pad
    constructor: (@parent, @label, @dir, @multi) ->
      @multi ?= dir is 'out'
      @connections = []
      @lines = []
    
    remove: ->
      for connection in @connections
        @connection.removeTo @, true
      for line in @lines
        removeConnection @line

    connectTo: (other, sub) ->
      unless sub
        unless @canConnect() and other.canConnect()
          return
      @connections.push other
      @circle.attr fill: 'lightgray'
      unless sub
        remove = =>
          @removeTo other
          paper.safari()
        other.connectTo @, true
        line = addConnection @circle, other.circle, 'blue', 'black|3', remove
        @lines.push line
        other.lines.push line

    removeTo: (other, sub) ->
      for i of @connections
        if @connections[i] is other
          @connections.splice i, 1
          unless sub
            other.removeTo @, true
            removeConnection @lines[i]
          @lines.splice i, 1
          break
      @circle.attr fill: 'white'  unless @connections.length

    canConnect: ->
      @multi or @connections.length is 0

    fixConnections: ->
      for line in @lines
        addConnection line.from, line.to, line
      paper.safari()

  addNode: (args...) ->
    new Node args...
    @
