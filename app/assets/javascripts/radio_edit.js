
/** Radio edition page. */
var radioEditPage = {

  initialize: function() {
    // Update the image when the URL has changed
    artistEditPage.bindImageChange('#radio_name');

  },

  finalize: function() {
    artistEditPage.unbindImageChange('#radio_name');
  }

};
