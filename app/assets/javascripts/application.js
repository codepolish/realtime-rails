// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery_ujs
//= require turbolinks
//= require_tree .
//= require_self

$(function() {
  ws = new WebSocket('ws://'+window.location.hostname+':'+(parseInt(window.location.port, 10) || 80)+'/chat')
  ws.onopen = function (event) {
    $('#chat').append('<li>New Chat!</li>');
  };
  ws.onclose = function (event) {
    $('#chat').append('<li>Chat Over!</li>');
  };
  ws.onmessage = function (event) {
    $('#chat').append('<li>'+event.data+'</li>');
  };

  var sendMessage = function () {
    if ($('#message').val() != '') {
      ws.send($('#message').val());
      $('#message').val('');
    }
  }

  $('button').click(function(e) {
    sendMessage();
  });
  $('#message').keypress(function(e) {
    if (e.charCode == 13) {
      sendMessage();
    }
  });
});
