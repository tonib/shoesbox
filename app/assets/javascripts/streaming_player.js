//= require jquery.cookie

/** The HTML streaming player. */
var streamingPlayer = {

  // Play file songs (mp3 files) source
  SOURCE_FILE_SONGS: 0,

  // Play radio source
  SOURCE_RADIO: 1,

  /** The audio player. null if it has not been initialized. */
  audio_tag: null,

  /** audio_tag.play() has been called? */
  play_called: false,

  /** The current play list id */
  play_list_id: null,

  /** The current play list song id */
  play_list_song_id: null,

  /** The current radio id */
  radio_id: null,

  /** The current player state ("PLAYING", "STOPPED" or "PAUSED") */
  state: "STOPPED",

  /** The play mode (SOURCE_FILE_SONGS or SOURCE_RADIO) */
  mode: 0,

  /** Initialize the audio player. */
  initialize: function() {

    // Create the audio player
    streamingPlayer.audio_tag = document.createElement('audio');

    // audio tag addEventListener is not supported on IE8
    try {
      // Add an event when the play finish.
      streamingPlayer.audio_tag.addEventListener('ended', function() {
        if( streamingPlayer.state == 'PLAYING' )
          // Request the next song
          streamingPlayer.sendMusicCommand( 'next' );
      });
      // Add error handling
      streamingPlayer.audio_tag.addEventListener('error', function(e) {
        console.log(e);
        if( streamingPlayer.state == 'PLAYING' )
          streamingPlayer.sendMusicCommand( 'next' );
      });
    }
    catch(e) {}

    // Check the initial status:
    var initialState = $.cookie("state");
    if( $.cookie("mode") == 'streaming' &&
        ( initialState == "PLAYING" || initialState == "PAUSED" ) )
      streamingPlayer.sendMusicCommand( 'stop' );

    // Set the initial volume
    var volume = $.cookie("volume");
    if( volume )
      streamingPlayer.changeVolume( parseInt(volume) );

  },

  sendMusicCommand: function( command ) {
    var url = $('#music_cmd_player_path').val();

    $.get(url, { cmd: command },
      function(data) {},
      'script'
    );
  },

  /**
    * Play a song
    * @param play_list_id Id. of PlayList wich the song to play belongs
    * @param play_list_song_id Id. of the Song to play
    * @param song_url Song URL to play
    */
  play_song: function(play_list_id, play_list_song_id, song_url) {
    streamingPlayer.play_list_id = play_list_id;
    streamingPlayer.play_list_song_id = play_list_song_id;
    streamingPlayer.mode = streamingPlayer.SOURCE_FILE_SONGS;
    streamingPlayer.play_url(song_url);

    // Move the play slider to 0:0
    if( pageState.getPageId() == 'playerPage' ) {
      var timer = pageState.getPage().songTimer;
      if( timer )
        timer.timerTick();
    }
  },

  /** Play a radio
    * @param radio_id Id of Radio to play
    * @param radio_url Radio URL to play
    */
  play_radio: function(radio_id, radio_url) {
    streamingPlayer.radio_id = radio_id;
    streamingPlayer.mode = streamingPlayer.SOURCE_RADIO;
    streamingPlayer.play_url(radio_url);
  },

  /** PRIVATE: Play a url on the audio tag. */
  play_url: function(url) {
    streamingPlayer.audio_tag.src = url;
    streamingPlayer.audio_tag.play();
    streamingPlayer.play_called = true;
    streamingPlayer.state = "PLAYING";
  },

  /**
    * Stop the current play
    */
  stop: function() {
    streamingPlayer.audio_tag.pause();
    // Avoid buffering:
    streamingPlayer.audio_tag.src = '';
    streamingPlayer.state = "STOPPED";
  },

  /**
    * Change the volume
    @param volume_percentage Integer with the volume percentage
    */
  changeVolume: function(volume_percentage) {
    streamingPlayer.audio_tag.volume = volume_percentage / 100.0;
  },

  /**
    * Pause the current play
    */
  pause: function() {
    streamingPlayer.audio_tag.pause();
    streamingPlayer.state = "PAUSED";
  },

  /**
    * Resume a paused song
    */
  resume: function() {
    streamingPlayer.audio_tag.play();
    streamingPlayer.play_called = true;
    streamingPlayer.state = "PLAYING";
  },

  /**
    * Enable auto play on smart devices
    */
  enablePlay: function() {
    if( !streamingPlayer.play_called ) {
      try {
        streamingPlayer.audio_tag.play();
      }
      catch(e) {
        console.log(e);
      }
      streamingPlayer.play_called = true;
    }
  },

  /**
    * Refresh the player state on the browser if it's needed
    */
  refreshPlayerIfNeeded: function() {

    // If there is no streaming player, dont update the state
    if( streamingPlayer.state == "STOPPED" )
      return;

    // If the state has not changed, dont update
    if( $.cookie('state') == streamingPlayer.state &&
        $.cookie('play_list_id') == streamingPlayer.play_list_id &&
        $.cookie('play_list_song_id') == streamingPlayer.play_list_song_id &&
        $.cookie('source') == streamingPlayer.mode &&
        $.cookie('radio_id') == streamingPlayer.radio_id
      )
      return;

    // Update the remote state
    $.cookie('state', streamingPlayer.state);
    $.cookie('play_list_id', streamingPlayer.play_list_id);
    $.cookie('play_list_song_id', streamingPlayer.play_list_song_id);
    $.cookie('source', streamingPlayer.mode);
    $.cookie('radio_id', streamingPlayer.radio_id);
    streamingPlayer.sendMusicCommand('refresh');

  }

};

// Initialization: ONLY ONCE, NOT EATCH TIME TURBOLINKS LOADS A NEW PAGE
$(function() {
  console.log('streamingPlayer.initialize');
  streamingPlayer.initialize();
});
