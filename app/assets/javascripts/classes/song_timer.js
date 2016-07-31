
/**
  Class to handle a song timer
*/
SongTimer = function(handleSlider) {

  // Number of seconds of the current playing song
  this.currentSeconds = 0;
  // Second from 1970 when the timer was started
  this.localStartSecond = 0;
  // Song play second when the page was downloaded
  this.remoteStartSecond = 0;
  // Have we called to refresh the player panel?
  this.playerRefreshed = false;
  // Number of seconds to add due to pauses
  this.seconds_offset = 0.0;
  // The user is dragging the play slidder?
  this.playSliderDragging = false;
  // The player is paused?
  this.paused = false;
  // Are we playing streaming?
  this.isStreaming = false;

  // Initialize the play slider
  var that = this;
  var $s = $('#playSlider');
  if( handleSlider && $s.length ) {
    this.$slider = $s
      .slider({
        formatter: function(value) { return SongTimer.formatSeconds( value ); }
      })
      .on('slideStart', function() {
        that.playSliderDragging = true;
      })
      .on('slideStop', function() {
        that.playSliderDragging = false;
        that.onPlaySliderChanged();
      })
      .data('slider');
  }
}

/** Initialize the timer */
SongTimer.prototype.start = function() {

  // Stop the current timer
  this.stop();
  this.playerRefreshed = false;

  // Record the local start time
  this.localStartSecond = SongTimer.getLocalTime();

  this.isStreaming = $('#is_streaming').val() == 'true';

  // If there is no song playing exit
  var $start = $('#start_time');
  if( !$start.length ) {
    if( this.$slider )
      $('#playSliderSlider').hide();
    return;
  }

  // Show the slider
  if( this.$slider )
    $('#playSliderSlider').show();

  // Seconds offset:
  this.seconds_offset = Math.floor( parseFloat( $('#seconds_offset').val() ) );

  // Store the server start time
  var start_time = $start.val();
  var now_on_server = $('#now_on_server').val();
  this.remoteStartSecond = Math.floor( (now_on_server - start_time) / 1000.0 );

  // Store the song length
  this.songSeconds = parseInt($('#song_seconds').val());

  // Display the initial elapsed time
  var currentSecond = this.getCurrentSecond();
  $('.now_playing').text(SongTimer.formatSeconds(currentSecond));

  // Check if the song is paused:
  this.paused = $('#paused').val() === 'true';
  if( !this.paused ) {
    // Add the timer
    //console.log("timer start");
    var that = this;
    this.timer = setInterval(function() {
      that.timerTick();
    }, 1000);
  }

  if( this.$slider ) {
    if( !this.paused )
      this.$slider.enable();
    else
      // Disable the seek if the song is paused
      // (seek is not supported by mpg321 if the song is pause)
      this.$slider.disable();

    this.$slider.setAttribute('max' , this.songSeconds);
    this.$slider.setValue(currentSecond);
  }

}

/** Calculate the current playing second.
  * @return The playing second
  */
SongTimer.prototype.getCurrentSecond = function() {

  if( this.isStreaming )
    return Math.round(streamingPlayer.audio_tag.currentTime, 0);

  if( this.paused )
    return this.seconds_offset;
  else
    return this.remoteStartSecond + SongTimer.getLocalTime()
      - this.localStartSecond + this.seconds_offset;
}

/** Get the local time, in seconds from 1970. */
SongTimer.getLocalTime = function() {
  return Math.floor( Date.now() / 1000 );
}

/** Function called each second. */
SongTimer.prototype.timerTick = function() {
  // Display the elapsed time
  var currentSecond =  this.getCurrentSecond();
  $('.now_playing').text( SongTimer.formatSeconds( currentSecond ) );
  if( this.$slider && !this.playSliderDragging )
    this.$slider.setValue( currentSecond );

  if( !this.playerRefreshed  && currentSecond > this.songSeconds &&
      !this.isStreaming) {
    // Song finished. Refresh the page to watch the new song
    this.playerRefreshed = true;
    $.getScript($('#music_cmd_player_path').val() + '?cmd=refresh');
  }
}

/** Clean the current timer. */
SongTimer.prototype.stop = function() {
  if( this.timer ) {
    //console.log("stop");
    clearInterval(this.timer);
    this.timer = null;
  }
}

/** Unbind the timer events. */
SongTimer.prototype.unbind = function() {
  this.stop();
  if( this.$slider ) {
    this.$slider.destroy();
    this.$slider = null;
  }
}

/** The play slider has been dragged event. */
SongTimer.prototype.onPlaySliderChanged = function() {

  if( this.isStreaming ) {
    streamingPlayer.audio_tag.currentTime = this.$slider.getValue();
    return;
  }

  var percentage = 0.0;
  if( this.songSeconds > 0.0 )
    percentage = ( this.$slider.getValue() / this.songSeconds ) * 100.0;

  var url = $('#music_cmd_player_path').val() + '?cmd=change_play_time&percentage=' +
    percentage;
  $.getScript(url);

}

/** Format a number of seconds to string.
  * @param seconds Number of seconds to Format
  * @return String with the number of seconds
*/
SongTimer.formatSeconds = function(seconds) {
  current_second = Math.floor(seconds);
  minutes = Math.floor(seconds / 60);
  txtSeconds = (seconds % 60).toString();
  if( txtSeconds.length == 1 )
    txtSeconds = "0" + txtSeconds;

  return minutes.toString() + ":" + txtSeconds;
}
