
var youtubePage = {

  /** Page initialization */
  initialize: function() {
    autocomplete( '#artist_name' , $('#suggest_artists_path').val() );
    autocomplete( '#album_name' , $('#suggest_albums_path').val() );
  },

  finalize: function() {
    autocomplete_unbind( '#artist_name' );
    autocomplete_unbind( '#album_name' );
  }

};
