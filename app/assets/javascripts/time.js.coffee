App.TimeController = Ember.ObjectController.extend
  init: ->
    @setTime()

  setTime: ->
    source = new EventSource('/time')
    source.addEventListener 'time', =>
      @set('content', new Date(JSON.parse(event.data).time))
