
/** The small player on the bottom of all pages. */
var smallPlayer = {

  // The song timer. It can be null
  songTimer: null,

  // Initialize page
  initialize: function(restoreFromCache) {

    if(restoreFromCache) {
      // Update player state
      $('#lnk_refresh_player').click();
      return;
    }

    if( !playerPage.isPlayingRadio() ) {
      // Start the timer
      smallPlayer.songTimer = new SongTimer(false);
      smallPlayer.songTimer.start();
    }

  },

  // Finalize the page
  finalize: function() {

    if( smallPlayer.songTimer ) {
      // Stop the timer
      smallPlayer.songTimer.unbind();
      smallPlayer.songTimer = null;
    }

  }

};
