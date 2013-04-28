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
      if data.remove
        @removeMember(data.remove)
      else if data.add
        @addMember(data.add)
      else
        @addToLog(data)
    Ember.$(window).unload ->
      socket.close()
    @set('socket', socket)

  removeMember: (member) ->
    @addToLog({notice: "#{member} has disconnected"})
    @set('members', @get('members').without(member))

  addMember: (member) ->
    @addToLog({notice: "#{member} has joined"})
    @set('members', @get('members').concat(member))

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
