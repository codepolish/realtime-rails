App.TextField = Ember.TextField.extend
  didInsertElement: ->
    @$().focus()

App.TableCell = Ember.View.extend
  tagName: 'td'
  didInsertElement: ->
    $(window).scrollTop($(window).height())

App.ChatController = Ember.Controller.extend
  init: ->
    @_super()
    @set('log', [])
    @set('members', [])
    @getUsername()
    @setupSocket()

  getUsername: ->
    @set('username', prompt('Please choose a username') || 'Anonymous coward')

  setupSocket: ->
    socket = new WebSocket("ws://#{window.location.host}/chat")
    socket.onopen = =>
      @sendMessage({username: @get('username')})
      @set('connected', true)
    socket.onclose = =>
      @addToLog({notice: 'You have been disconnected!'})
      @set('connected', false)
    socket.onmessage = (event) =>
      data = JSON.parse(event.data)
      debugger
      if data.remove
        @removeMember(data.member)
      else if data.add
        @addMember(data.member)
      else
        @addToLog(data)
    Ember.$(window).unload ->
      socket.close()
    @set('socket', socket)

  removeMember: (data) ->
    @addToLog({notice: "#{member} has disconnected"})
    @set('members', @get('members').without(data))

  addMember: (data) ->
    @addToLog({notice: "#{member} has joined"})
    debugger
    @set('members', @get('members').concat(data))

  connect: ->
    if !Ember.isEmpty(@get('username'))
      @setupSocket()
    else
      window.alert('Please choose a username!')

  sendMessage: (json) ->
    @get('socket').send(JSON.stringify(json))

  submitMessage: ->
    if !Ember.isEmpty(@get('chat'))
      @sendMessage({message: @get('chat')})
      @set('chat', undefined)

  addToLog: (data) ->
    @set('log', @get('log').concat(data))
