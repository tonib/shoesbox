
//= require jquery
//= require bootstrap/tab
//= require toastr
//= require classes/song_timer
//= require songs_filter
//= require classes/table_checks
//= require classes/scrollable_table
//= require bootstrap-slider

var playerPage = {

  // Used to identify the page
  pageId: 'playerPage',

  // Id of the last played song / radio
  lastPlayedId: 0,

  // The song timer. It can be null
  songTimer: null,

  // Songs tables
  queueTable: null,

  // Songs filter
  queueFilter: null,

  // Songs selection
  queueChecks: null,

  // Songs operations
  tableOps: null,

  // The volume control
  volume: null,

  /** True if we are playing radio. False if we are playing songs. */
  isPlayingRadio: function() {
    return $('#play_mode').val() == "RADIO";
  },

  /** Paint the current playing song on the queue table. */
  paintCurrentSong: function () {

    // Are we playing radio?
    var playingRadio = playerPage.isPlayingRadio();
    var prefix = playingRadio ? '#radio_' : '#play_';
    var play_id_hidded = playingRadio ? '#radio_id' : '#playsong_id';

    // Unpaint the last song / radio:
    if( playerPage.lastPlayedId > 0 )
      $( prefix + playerPage.lastPlayedId).removeClass('success');

    playerPage.lastPlayedId = parseInt( $( play_id_hidded ).val() );

    // Paint the new
    if( playerPage.lastPlayedId > 0 )
      $( prefix + playerPage.lastPlayedId).addClass('success');

  },

  /** Initialize page */
  initialize: function(restoreFromCache) {

    if( !playerPage.isPlayingRadio() ) {
      // Start the timer
      playerPage.songTimer = new SongTimer(true);
      playerPage.songTimer.start();
    }

    // Paint the current playing song row
    playerPage.paintCurrentSong();

    // Initialize tables:
    playerPage.queueTable = new ScrollableTable('queue' , $('#load_page').val() );
    playerPage.queueChecks = new TableChecks(playerPage.queueTable);
    playerPage.queueTable.onNewPageAdded(function() {
      playerPage.paintCurrentSong();
    });
    playerPage.tableOps = new SongsTableOps(playerPage.queueTable,
      playerPage.queueChecks);

    // Initialize filters
    playerPage.queueFilter = new SongsFilter('queue', playerPage.queueTable );

    // Remove selected songs from the queue
    $('#remove_songs_queue').click(function(e) {
      e.preventDefault();

      var ids = playerPage.queueChecks.selectedRowsIds('data-playlistid');
      if( ids.length == 0 ) {
        alert("Please, select the songs to remove");
        return;
      }

      if( !confirm('Are you sure you want to remove ' +
        ( ids == 'all' ? 'all selected' : ids.length ) + ' songs from the queue?') )
        return;

      // Do the call
      var url = $('#music_cmd_post_path').val();
      var params = playerPage.queueChecks.getOperationParameters(ids, 'play_list_song_ids');
      params['cmd'] = 'remove_queue_songs'
      $.post(url, params, function(data) {}, 'script' );
    });

    // if(restoreFromCache)
    //   // Update player state
    //   $('#lnk_refresh_player').click();

    // Initialize the volume control
    playerPage.volume = new VolumeControl();

    // Play list combo changes
    $('#play_lists').change(function() {

      var play_list_id = $(this).val();
      // Change the play list
      url = $('#change_play_list_player_path').val() +
        "?play_list_id=" + play_list_id;
      // Reload the page, outside turbolinks:
      window.location = url;
    });

    // If we are playing streaming and the cookies state does not mach the
    // streaming state, refresh the player state
    if( $('#is_streaming').val() == 'true' )
      streamingPlayer.refreshPlayerIfNeeded();

  },

  /** It checks if somebody else has changed the speakers play mode between
      radio and mp3. In that case, reload the entire page. */
  checkModeChange: function() {
    var modeSwitched = false;
    if( playerPage.isPlayingRadio() )
      modeSwitched = $('#queue').length > 0;
    else
      modeSwitched = $('#radios').length > 0;

    if( modeSwitched )
      // Force a page reload
      location.reload(true);
  },

  // Finalize the page
  finalize: function() {

    if( playerPage.songTimer ) {
      // Stop the timer
      playerPage.songTimer.unbind();
      playerPage.songTimer = null;
    }

    playerPage.queueTable.unbind();
    playerPage.queueTable = null;

    playerPage.queueFilter.unbind();
    playerPage.queueFilter = null;

    playerPage.queueChecks.unbind();
    playerPage.queueChecks = null;

    playerPage.tableOps.unbind();
    playerPage.tableOps = null;

    playerPage.volume.unbind();
    playerPage.volume = null;

    $('#remove_songs_queue').unbind();
    $('#play_lists').unbind();

  }

};
