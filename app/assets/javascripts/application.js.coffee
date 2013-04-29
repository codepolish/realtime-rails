#= require jquery
#= require jquery_ujs
#= require handlebars
#= require ember
#= require_self
#= require chat
#= require draw
#= require time

window.App = Ember.Application.create()

App.Router.map ->
  this.route 'chat'
  this.route 'draw'
  this.route 'time'
