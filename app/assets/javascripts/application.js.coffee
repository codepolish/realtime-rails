#= require jquery
#= require jquery_ujs
#= require handlebars
#= require ember
#= require_self

window.App = Ember.Application.create()

App.Router.map ->
  this.route 'chat'

App.TextField = Ember.TextField.extend
  didInsertElement: ->
    @$().focus()

App.ChatController = Ember.Controller.extend
  init: ->
    @_super()
    @set('log', [])
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
      @addToLog(JSON.parse(event.data))
    Ember.$(window).unload ->
      socket.close()
    @set('socket', socket)

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
