
# Stores the music player state for the streaming user reproduction
class PlayerStateStreaming

  STOPPED = "STOPPED"
  PAUSED = "PAUSED"
  PLAYING = "PLAYING"

  attr_accessor :volume

  # The current play list
  attr_reader :play_list

  # The Radio we are currently playing. It can be nil.
  attr_accessor :radio

  # The PlayListSong we are currently playing, or the last song played.
  # It can be nil.
  attr_accessor :play_list_song

  # Music source. It can be PlayerState::SOURCE_FILE_SONGS or PlayerState::SOURCE_RADIO
  attr_reader :mode

  # Load the state from cookies
  # [+cookies+] The request cookies
  def initialize(cookies)
    @cookies = cookies.permanent
    @play_list = PlayerStateStreaming.current_reproduction_queue(cookies)
    @play_list_song = PlayListSong.find_by( id: cookies[:play_list_song_id].to_i )
    @radio = Radio.find_by( id: cookies[:radio_id].to_i )
    @volume = ( cookies[:volume] ? cookies[:volume].to_i : 100 )
    @state = cookies[:state]
    @state = "STOPPED" if !@state
    @mode = ( cookies[:source] ? cookies[:source].to_i : PlayerState::SOURCE_FILE_SONGS )
  end

  def playing?
    #return @play_list_song && ( @state == PLAYING || @state == PAUSED )
    return false if @state == STOPPED
    return false if @mode == PlayerState::SOURCE_FILE_SONGS && !@play_list_song
    return false if @mode == PlayerState::SOURCE_RADIO && !@radio
    return true
  end

  def paused
    return @state == PAUSED
  end

  def play_start_to_j
    return nil
  end

  def seconds_offset
    return nil
  end

  def is_streaming?
    return true
  end

  def execute_cmd(controller, cmd, cmd_params = {})
    case cmd
    when 'play_song'
      @mode = PlayerState::SOURCE_FILE_SONGS
      if cmd_params[:song_id]
        # Check if the song is on the queue
        cmd_params[:play_list_song_id] = @play_list.find_or_add_song(cmd_params[:song_id]).id
      end
      @play_list_song = PlayListSong.find_by( id: cmd_params[:play_list_song_id] )
      streaming_js_command = play_command_js(controller)

    when 'play_radio'
      @mode = PlayerState::SOURCE_RADIO
      @radio = Radio.find_by( id: cmd_params[:radio_id] )
      streaming_js_command = play_command_js(controller)

    when 'stop'
      streaming_js_command = "streamingPlayer.stop()"
      @state = STOPPED

    when 'pause'
      if @state == PAUSED
        streaming_js_command = "streamingPlayer.resume()"
        @state = PLAYING
      elsif @state == PLAYING
        streaming_js_command = "streamingPlayer.pause()"
        @state = PAUSED
      end

    when 'change_volume'
      @volume = cmd_params[:volume].to_i
      streaming_js_command = "streamingPlayer.changeVolume(#{@volume.to_s})"

    when 'next'
      if @mode == PlayerState::SOURCE_FILE_SONGS
        @play_list_song = @play_list.next_song(@play_list_song)
      else
        @radio = Radio.next_radio( @radio )
      end
      streaming_js_command = play_command_js(controller)

    when 'previous'
      if @mode == PlayerState::SOURCE_FILE_SONGS
        @play_list_song = @play_list.next_song(@play_list_song, :backward)
      else
        @radio = Radio.next_radio( @radio , :backward )
      end
      streaming_js_command = play_command_js(controller)

    when 'start'
      if @state == PAUSED
        streaming_js_command = "streamingPlayer.resume()"
        @state = PLAYING
      elsif @state == STOPPED
        if @mode == PlayerState::SOURCE_FILE_SONGS
          @play_list_song = @play_list.start_song( @play_list_song )
        else
          @radio = Radio.start_radio( @radio )
        end
        streaming_js_command = play_command_js(controller)
      end

    when 'queue_all_and_shuffle'
      # Clean the current queue
      @play_list.play_list_songs.clear

      # Get all songs and random sort them
      songs_ids = Song.all.pluck( :id ).to_a.shuffle

      # Add the first song and play, to avoid wait:
      @play_list.add_songs_ids( [songs_ids[0] ] , 1)
      @play_list_song = @play_list.find_or_add_song( songs_ids[0] )
      streaming_js_command = play_command_js(controller)

      # Add the other songs in background
      Task.do_task('Play all random') do |task|
        songs_ids.shift
        # Add the other songs
        @play_list.add_songs_ids(songs_ids, 2)
      end

    when 'remove_queue_songs'
      ids = cmd_params[:play_list_song_ids]
      puts "*** #{ids.inspect}"
      # If we are deleting the current playing song, stop the play
      if @play_list_song && ids.include?( @play_list_song.id )
        streaming_js_command = "streamingPlayer.stop()"
        @state = STOPPED
      end
      # Remove the songs
      PlayListSong.delete(ids)

    end

    streaming_js_command += ";" if streaming_js_command

    save_state_to_cookies
    return streaming_js_command , CmdResult.new
  end

  #########################################
  protected
  #########################################

  # Get the current PlayList from the request cookies
  # [+returns+] The PlayList
  def self.current_reproduction_queue(cookies)
    play_list = nil
    play_list_id = cookies[:play_list_id]
    if play_list_id
      play_list = PlayList.find_by(id: play_list_id.to_i)
    end
    if !play_list
      play_list = PlayList.reproduction_queue
    end
    return play_list
  end

  def save_state_to_cookies
    @cookies[:play_list_id] = @play_list.id.to_s
    @cookies[:play_list_song_id] = @play_list_song ? @play_list_song.id.to_s : nil
    @cookies[:radio_id] = @radio ? @radio.id.to_s : nil
    @cookies[:source] = @mode.to_s
    @cookies[:volume] = @volume.to_s
    @cookies[:state] = @state
  end

  def play_command_js(controller)
    streaming_js_command = ''
    if @mode == PlayerState::SOURCE_FILE_SONGS
      if @play_list_song
        song_url = controller.song_download_path(@play_list_song.song)
        streaming_js_command = "streamingPlayer.play_song(#{@play_list.id.to_s} , #{play_list_song.id.to_s} , '#{song_url}')"
        @state = PLAYING
      end
    else
      # Radio
      if @radio
        streaming_js_command = "streamingPlayer.play_radio(#{@radio.id} , '#{radio.streaming_url}' )"
        @state = PLAYING
      end
    end
    return streaming_js_command
  end

end
