#= require jquery
#= require jquery_ujs
#= require handlebars
#= require ember
#= require_self

window.App = Ember.Application.create()

App.IndexController = Ember.Controller.extend
  init: ->
    @_super()
    @set('log', [])
    @setupSocket()

  setupSocket: ->
    socket = new WebSocket("ws://#{window.location.host}/chat")
    socket.onopen = =>
      @addToLog('Connected!')
      @set('connected', true)
    socket.onclose = =>
      @addToLog('Disconnected!')
      @set('connected', false)
    socket.onmessage = (event) =>
      @addToLog(event.data)
    @set('socket', socket)

  send: ->
    if !Ember.isNone(@get('chat'))
      @get('socket').send(@get('chat'))
      @set('chat', undefined)

  addToLog: (message) ->
    @set('log', @get('log').concat(message))
