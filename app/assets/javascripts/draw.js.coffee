App.CanvasView = Ember.View.extend
  tagName: 'canvas'
  attributeBindings: ['width', 'height']
  classNameBindings: ['drawing']
  width: 3000
  height: 3000
  didInsertElement: ->
    @set('controller.canvasContext', @.$()[0].getContext('2d'))
  mouseMove: (event) ->
    if @get('drawing')
      @get('controller.socket').send(JSON.stringify({newX: event.offsetX, newY: event.offsetY}))
      @get('controller').send('drawLine', {user_id: @get('controller.user_id'), newX: event.offsetX, newY: event.offsetY})
  mouseDown: (event) ->
    @set('drawing', true)
  mouseUp: (event) ->
    @set('drawing', false)
    @get('controller.socket').send(JSON.stringify({stopDrawing: true}))

App.DrawController = Ember.Controller.extend
  init: ->
    @_super()
    @set('users', {})
    @setupSocket()

  setupSocket: ->
    socket = new WebSocket("ws://#{window.location.host}/draw")
    socket.onopen = =>
      @set('connected', true)
    socket.onclose = =>
      @set('connected', false)
    socket.onmessage = (event) =>
      data = JSON.parse(event.data)
      if data.stopDrawing
        @stopDrawing(data.user_id)
      else if data.connect
        @set('user_id', data.connect)
      else
        unless data.user_id == @get('user_id')
          @drawLine(data)

    Ember.$(window).unload ->
      socket.close()
    @set('socket', socket)

  drawLine: (data) ->
    if @wasDrawing(data.user_id)
      console.log('here')
      context = @get('canvasContext')
      context.beginPath()
      context.moveTo(@get("users.#{data.user_id}.oldX"), @get("users.#{data.user_id}.oldY"))
      context.lineTo(data.newX, data.newY)
      context.stroke()
    @setLocation(data)

  stopDrawing: (user_id) ->
    @set("users.#{user_id}.oldX", undefined)
    @set("users.#{user_id}.oldY", undefined)

  wasDrawing: (user_id) ->
    @get("users.#{user_id}") && @get("users.#{user_id}.oldX") && @get("users.#{user_id}.oldY")

  setLocation: (data) ->
    user = @get("users.#{data.user_id}") || {}
    user.oldX = data.newX
    user.oldY = data.newY
    @set("users.#{data.user_id}", user)
