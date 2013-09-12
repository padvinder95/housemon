# adapted from https://github.com/ryanwmoore/JsDataFlowEditor
# which was forked from https://github.com/daeken/JsDataFlowEditor

window.createDiagramEditor = (domid, width, height, options) ->
  anchor = anchorCallback = selectedNode = null
  nodes = []

  theme =
    nodeFill: '#eee'
    pointInactive: '#fff'
    pointActive: '#ccc'
    connectingFill: '#fff'
    connectingStroke: '#000'
    connectingStrokeWidth: 3
    lineFill: 'blue'
    lineStroke: '#000'
    lineStrokeWidth: 3
  theme[k] = v  for k,v of options ? {}

  paper = Raphael domid, width, height

  allowConnection = (point) ->

    point.circle.mousedown (e) =>
      (e.originalEvent or e).preventDefault()
      if not point.multi and point.connections.length
        other = point.connections[0]
        beginning = other.circle
        point.removeConnection other
        anchor = other
      else
        anchor = point

      b = point.circle.getBBox()
      cursor = paper.circle e.offsetX, e.offsetY, 1
      line = paper.connection anchor.circle, cursor,
        theme.connectingFill,
        theme.connectingStroke + '|' + theme.connectingStrokeWidth

      jo = document.getElementById(domid)
      
      jo.onmouseup = ->
        cursor.remove()
        paper.removeConnection line
        anchor = anchorCallback = null
        jo.onmouseup = jo.onmousemove = null

      sx = sy = undefined
      
      jo.onmousemove = (e) ->
        sx ?= e.pageX
        sy ?= e.pageY
        cursor.translate e.pageX - sx, e.pageY - sy
        paper.connection line
        sx = e.pageX
        sy = e.pageY

      anchorCallback = (target) =>
        unless target.dir is anchor.dir or target.parent is anchor.parent
          anchor.connect target

    # point.circle.mouseover (e) ->
    #   console.log 'oo1', e

    point.circle.mouseup (e) ->
      anchorCallback? point

  class graphEditor
    
    addNode: (x, y, title, inputs, outputs) ->
      node = new graphNode title

      for input in inputs ? []
        node.addPoint input, 'in', input[0] is '*'
      for output in outputs ? []
        node.addPoint output, 'out'
      
      nodes.push node
      cx = cy = null

      start = ->
        cx = cy = 0
        
      move = (dx, dy) ->
        group.translate dx - cx, dy - cy
        cx = dx
        cy = dy
        suppressSelect = true
        group.toFront()
        for p in node.points
          p.fixConnections()
        paper.safari()

      node.parent = @

      node.on 'focus', ->
        selectedNode?.emit 'blur'  unless @ is selectedNode
        selectedNode = @
        @element.toFront().attr 'stroke-width', 2

      node.on 'blur', ->
        selectedNode = null
        @element.attr 'stroke-width', 1

      group = node.element = paper.set()

      height = 0
      info =
        in: { elements: [], count: 0, width: 0 }
        out: { elements: [], count: 0, width: 0 }

      node.points.forEach (point) ->
        label = point.label = paper.text x, y, point.label
        label.attr fill: '#000', 'font-size': 12
        circle = point.circle = paper.circle(x, y, 7.5)
        circle.attr stroke: '#000', fill: theme.pointInactive
        bbox = label.getBBox()
        height = bbox.height
        width = bbox.width

        e = info[point.dir]
        e.elements.push { label, width, circle }
        e.count += 1
        e.width = bbox.width  if bbox.width > e.width

        group.push label, circle.toFront()
        allowConnection point

      title = paper.text(x, y, node.title)
      title.attr fill: '#000', 'font-size': 16, 'font-weight': 'bold'
      bbox = title.getBBox()

      count = Math.max info.in.count, info.out.count
      nHeight = 8 + bbox.height + count * (height + 5)
      nWidth = 60 + Math.max(50, bbox.width, info.in.width + info.out.width)
      
      rect = paper.rect(x, y, nWidth, nHeight, 6)
      rect.attr fill: theme.nodeFill, 'fill-opacity': 0.9

      group.splice 0, 0, rect.toBack(), title

      title.translate nWidth / 2, bbox.height / 2 + 3

      for dir, column of info
        pos = 14 + bbox.height
        column.elements.forEach (e) ->
          switch dir
            when 'in'
              e.circle.translate 12, pos
              e.label.translate 22 + e.width / 2, pos
            when 'out'
              e.circle.translate nWidth - 12, pos
              e.label.translate nWidth - 22 - e.width / 2, pos
          pos += height + 5

      suppressSelect = false

      rect.click ->
        if suppressSelect is true
          suppressSelect = false
        else
          node.emit if node is selectedNode then 'blur' else 'focus'

      rect.drag move, start

  class graphNode extends EventEmitter
    constructor: (@title) ->
      @points = []

      @.on 'remove', ->
        @emit 'blur'  if @ is selectedNode
        @element.remove()
        p.remove()  for p in @points

    addPoint: (label, dir, multi) ->
      npoint = @[label] = new point(@, label, dir, multi)
      @points.push npoint
      @
    
  class point
    constructor: (@parent, @label, @dir, @multi) ->
      @multi ?= dir is 'out'
      @connections = []
      @lines = []
    
    remove: ->
      for connection in @connections
        @connection.removeConnection @, true
      for line in @lines
        paper.removeConnection @line

    connect: (other, sub) ->
      unless sub
        if not @multi and @connections.length
          return false
        else
          return false  if not other.multi and other.connections.length
      @connections.push other
      @circle.attr fill: theme.pointActive
      if sub isnt true
        remove = =>
          @removeConnection other
          paper.safari()
        other.connect @, true
        line = paper.connection @circle, other.circle, theme.lineFill,
          theme.lineStroke + '|' + theme.lineStrokeWidth, remove
        @lines.push line
        other.lines.push line
      @parent.emit 'connect', @, other
      true

    removeConnection: (other, sub) ->
      for i of @connections
        if @connections[i] is other
          @connections.splice i, 1
          unless sub
            other.removeConnection @, true
            paper.removeConnection @lines[i]
          @lines.splice i, 1
          break
      @circle.attr fill: theme.pointInactive  unless @connections.length
      @parent.emit 'disconnect', @, other

    fixConnections: ->
      for i of @lines
        paper.connection @lines[i]
      paper.safari()

  new graphEditor

Raphael.fn.connection = (obj1, obj2, line, bg, removeHook) ->
  if obj1.line and obj1.from and obj1.to
    line = obj1
    obj1 = line.from
    obj2 = line.to
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
  ].join(',')
  if line and line.line
    line.bg and line.bg.attr(path: path)
    line.line.attr path: path
  else
    color = (if typeof line is 'string' then line else '#000')
    lineElem = @path(path)
    bgElem = (if (bg and bg.split) then @path(path) else null)
    if removeHook?
      dblclick = (e) ->
        (e.originalEvent or e).preventDefault()
        removeHook()
        lineElem.remove()
        bgElem?.remove()
      lineElem.dblclick dblclick
      bgElem?.dblclick dblclick
      
    line: lineElem.attr(
      stroke: color
      fill: 'none'
    ).toBack()
    bg: bg and bg.split and bgElem.attr(
      stroke: bg.split('|')[0]
      fill: 'none'
      'stroke-width': bg.split('|')[1] or 3
    ).toBack()
    from: obj1
    to: obj2

Raphael.fn.removeConnection = (connection) ->
  connection.line?.remove()
  connection.bg?.remove()
