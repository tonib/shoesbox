
//= require classes/forms

/** Settings edit page. */
var settingsEditPage = {

  initialize: function() {
    $('.keypad_link').click(function(e) {
      e.preventDefault();
      $('#setting_keypad_device').val( '/dev/input/by-id/' + $(this).text() );
    });
  },

  finalize: function() {
    $('.keypad_link').unbind();
  }

};
