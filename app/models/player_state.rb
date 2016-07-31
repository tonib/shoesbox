require_relative '../../lib/active_record_utils/arutils.rb'

# Stores the music player state for the physical device reproduction audio
# There is a single record on this table
class PlayerState < ActiveRecord::Base

  # Play file songs (mp3 files)
  SOURCE_FILE_SONGS = 0

  # Play radio
  SOURCE_RADIO = 1

  ###################################################
  # ATTRIBUTES
  ###################################################

  ##
  # :attr_accessor: play_start
  # Datetime when the current song was started to play. If there is no
  # song playing, this is nil. If the song is paused, this is the
  # pause time. If the song was paused and restarted, this is the
  # restart time

  ##
  # :attr_accessor: seconds_offset
  # Float. If the song was paused and restarted, play_start contains the
  # restart time, and this field the elapsed play time for the start time

  ##
  # :attr_accessor: paused
  # Boolean. True if the play is paused

  ##
  # :attr_accessor: volume
  # Integer. Volume gain. A value from 0 (=mute) to 100 (=maximum)

  ##
  # :attr_accessor: mode
  # Play mode. It can be SOURCE_FILE_SONGS or SOURCE_RADIO

  ###################################################
  # RELATIONS
  ###################################################

  ##
  # :attr_accessor: play_list_song
  # The PlayListSong we are currently playing, or the last song played.
  # It can be nil.
  belongs_to :play_list_song

  ##
  # :attr_accessor: radio
  # The Radio we are currently playing. It can be nil.
  belongs_to :radio

  ###################################################
  # MEMBERS
  ###################################################

  # Get the current play list
  def play_list
    return @play_list if @play_list
    @play_list = PlayList.reproduction_queue
    return @play_list
  end

  # Load the state from the db
  # [+returns+] The current state
  def self.load_state
    state = PlayerState
      .includes( :play_list_song , { :play_list_song => :song } )
      .take

    if !state
      state = PlayerState.new
      state.volume = 100
      state.seconds_offset = 0
      state.paused = false
    end

    return state
  end

  # Return true if the player is started
  def playing?
    self.play_start != nil
  end

  # Returns a String with the player state
  def to_s
    if !self.play_start
      "Stopped"
    else
      txtSong = self.play_list_song ? self.play_list_song.song.to_s : ''
      "Started #{txtSong} #{play_start}"
    end
  end

  # Save that we have started to play a song right now
  # [+returns+] True if the save was ok
  def save_playing
    self.play_start = DateTime.now
    self.paused = false
    self.seconds_offset = 0.0
    return ARUtils.save_cmdline(self)
  end

  # Save that we have stopped playing songs
  def save_stop
    self.play_start = nil
    self.paused = false
    self.seconds_offset = 0.0
    ARUtils.save_cmdline(self)
  end

  # Save that we have paused or restarted the song play
  # [+paused+] true if the play has been paused. False if it has beed restarted
  # [+song_play_time+] Elapsed seconds of the song play
  def save_pause(paused, song_play_time = 0.0)
    self.play_start = DateTime.now
    self.paused = paused
    self.seconds_offset = song_play_time
    ARUtils.save_cmdline(self)
  end

  # Returns the play start on javascript format
  # [+returns+] Number with milliseconds since 1970-01-01 00:00:00 UTC
  def play_start_to_j
    play_start.to_f * 1000
  end

  # Returns the current date on the server on javascript format
  # [+returns+] Number with milliseconds since 1970-01-01 00:00:00 UTC
  def self.now_on_server_to_j
    DateTime.now.to_f * 1000
  end

  def is_streaming?
    return false
  end

end
