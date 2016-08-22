
# Active record stuff
require 'active_record'
require_relative './cmd_result'
require_relative './keypad'
require_relative '../../app/models/constants'
require_relative '../../app/models/artist'
require_relative '../../app/models/album'
require_relative '../../app/models/song'
require_relative '../../app/models/task'
require_relative '../../app/models/play_list'
require_relative '../../app/models/player_state'
require_relative '../../app/models/setting'
require_relative '../../app/models/songs_editor'
require_relative '../../app/models/radio'
require_relative '../../app/models/log'

require_relative 'mpg321_client'
require_relative 'dbgeneration'
require_relative 'meta_generation'

# A song player
class Player

  # Id to play the first song of the queue
  FIRST_SONG = -1

  # Id to replay the last played song
  LAST_PLAYED_SONG = -2

  # Id to play the next song
  NEXT_SONG = -3

  # The root directory that contains all the music
  attr_accessor :music_directory

  # Constructor
  def initialize

    # The worker thread
    @current_worker_thread = nil

    # Connect to database
    config_path = File.dirname(__FILE__) + "/../../config/database.yml"
    ActiveRecord::Base.configurations = YAML::load(IO.read(config_path))
    ActiveRecord::Base.default_timezone = :local

    # Set execution mode (development / production). Default is production
    if( ARGV.any?{ |a| a == "--debug" || a == "-d" } )
      puts "Player running on debug mode"
      ActiveRecord::Base.establish_connection(:development)
      ActiveRecord::Base.logger = Logger.new(STDERR)  # Log SQL
    else
      ActiveRecord::Base.establish_connection(:production)
    end

    # The song player
    @song_player = Mpg321Client.new

    # Get the settings
    @settings = Setting.get_settings

    # Initial message
    if !@settings.initial_message.empty?
      speech( { message: @settings.initial_message , wait: true } )
    end

    # Get the last player state
    @player_state = PlayerState.load_state

    # Initialize the volume
    @song_player.gain( @player_state.volume )

    # Restart the play?
    start if @player_state.playing?

    # Initialize the keypad
    @keypad = Keypad.new(self)

  end

  # Say something on the server speakers with a creepy robot voice
  # [+params[:message]+] Text to say. If it's '*CURRENTPLAY*', it will be
  # the currently playing radio / song name (and artist)
  # [+params[:wait]+] Boolean. Should we wait until the speech has finished?.
  # Default is false
  def speech( params )

    if params[:message] == '*CURRENTPLAY*'
      # Replace by the current play info
      params[:message] = 'Nothing playing'
      if @player_state.mode == PlayerState::SOURCE_RADIO && @player_state.radio
        params[:message] = @player_state.radio.name
      end
      if @player_state.mode == PlayerState::SOURCE_FILE_SONGS && @player_state.play_list_song
        s = @player_state.play_list_song.song
        params[:message] = ( s.artist.name != Artist::UNKNOWN_ARTIST_NAME ? s.artist.name : '' )
        params[:message] += ' ' + s.name
      end
    end

    cmdLine = @settings.prepare_speech_cmd(params[:message])
    return if !cmdLine
    if params[:wait]
      system(*cmdLine)
    else
      Thread.new { system(*cmdLine) }
    end

  end

  # Start playing songs
  # [+play_list_song_id+] Integer with the id of the first PlayListSong to play, or
  # LAST_PLAYED_SONG, or FIRST_SONG, or NEXT_SONG
  def start(play_list_song_id = LAST_PLAYED_SONG)

    if @song_player.status == Mpg321Client::STATUS_PAUSED
      # Restart the play
      pause
      return
    end

    return if started?
    puts 'Starting player'

    # The reproduction queue
    queue = PlayList.reproduction_queue
    if next_song(queue, play_list_song_id)
      # Start play
      @current_worker_thread = Thread.new { worker_thread(queue) }
    end
  end

  # Are we currently playing songs?
  # [+returns+] True if we are playing songs
  def started?
    @current_worker_thread != nil
  end

  # Stop the player
  # [+returns+] True if the player was currently playing
  def stop
    return false if !started?

    @current_worker_thread.kill
    @current_worker_thread = nil
    @song_player.stop
    @player_state.save_stop
    return true
  end

  # Pause / resume the current play
  def pause
    if @song_player.pause
      # Save the pause state
      @player_state.save_pause(@song_player.status == Mpg321Client::STATUS_PAUSED,
        @song_player.current_second)
    end
  end

  # Play the next song
  def next
    changeCurrentSong(:forward)
  end

  # Play the previous song
  def previous
    changeCurrentSong(:backward)
  end

  # Check for file song changes on the music directory
  # [+clean+] True if we must clean the music database
  # [+returns+] A CmdResult with the search status
  def rescan_music(clean = false)
    stop if clean
    return result = searchMusicFiles(clean)
  end

  # Clean the music database and check for file song changes on the
  # music directory
  # [+returns+] A CmdResult with the search status
  def clean_db
    return rescan_music(true)
  end

  # Clears the reproduction queue, add all the available music, sort it
  # randomly and start to play
  def queue_all_and_shuffle
    Task.do_task('Play all music shuffled...') do |task|
      stop
      remove_song_from_state
      queue = PlayList.reproduction_queue
      # Clean the current queue
      queue.play_list_songs.clear
      # Get all songs and random sort them
      songs_ids = Song.all.pluck( :id ).to_a.shuffle
      # Add the first song and play, to avoid wait:
      queue.add_songs_ids( [songs_ids[0] ] , 1)
      start
      songs_ids.shift
      # Add the other songs
      queue.add_songs_ids(songs_ids, 2)
    end
    return CmdResult.new(:success, 'Play all started')
  end

  # Play some song of the reproduction queue
  # [+params[:play_list_song_id]+] Integer with the PlayListSong id to play
  # [+params[:song_id]+] Integer with the Song id to play
  # Only one of both parameters should be set
  def play_song(params)
    # Change to files mode if it's needed
    change_mode( { mode: PlayerState::SOURCE_FILE_SONGS } )

    if params[:song_id]
      # Check if the song is on the queue
      play_list_song = PlayList.reproduction_queue
        .find_or_add_song(params[:song_id])
      params[:play_list_song_id] = play_list_song.id
    end

    puts "play_list_song_id: #{params[:play_list_song_id]}"
    stop
    start( params[:play_list_song_id] )
  end

  # Play some song of the reproduction queue
  # [+params[:radio_id]+] Integer with the Radio id to play
  def play_radio(params)
    # Change to radio mode if it's needed
    change_mode( { mode: PlayerState::SOURCE_RADIO } )

    stop
    start( params[:radio_id] )
  end

  # Remove songs from the reproduction queue
  # [+params[:songs_ids]+] Array of PlayListSong ids to remove
  def remove_queue_songs(params)

    ids = params[:play_list_song_ids]
    puts "Removing #{ids.length} songs from playlist"

    # If we are deleting the current playing song, stop the play
    restart_server = false
    if @player_state.play_list_song && ids.include?( @player_state.play_list_song.id )
      restart_server = stop
      current_song = remove_song_from_state
    end

    # Remove the songs
    PlayListSong.delete(ids)

    if restart_server
      # Start playing the next available song:
      current_song = PlayList.reproduction_queue.next_song( current_song )
      if current_song
        start(current_song.id)
      end
    end

  end

  # Reloads the settings from the database
  def reload_settings
    puts "Reloading settings"
    @settings = Setting.get_settings
  end

  # Search metadata for music database (wikipedia links, images)
  # [+params[:clean]+] True if we must clean the current metadata
  def search_meta(params = {})
    meta = MetaGeneration.new(@settings)
    MetaGeneration.clean_metadata if params[:clean]
    meta.search_artists
    return CmdResult.new(:success , 'Metadata recalculation started' )
  end

  # Change or increase the play volume
  # [+params[:volume]+] The new volume. An integer from 0 to 100
  # [+params[:volume_increase]+] The volume increase. An integer from 0 to 100
  def change_volume(params)

    return if !params[:volume] && !params[:volume_increase]

    # mpg321 does not support change the volume when playing an URL
    # stopped = false
    # if @player_state.mode == PlayerState::SOURCE_RADIO
    #   stopped = stop
    # end

    if params[:volume]
      @player_state.volume = @song_player.gain( params[:volume].to_i )
    else
      @player_state.volume = @song_player.increase_gain( params[:volume_increase].to_i )
    end

    ARUtils.save_cmdline(@player_state)

    # if stopped
    #   start
    # end

  end

  # Change the current play time of the current play song
  # [+params[:percentage]+] Float. Percentaje of the song to play
  def change_play_time(params)
    percentage = params[:percentage].to_f;
    @song_player.jump_to_position(percentage)

    # Save the changes
    second = @player_state.play_list_song.song.seconds * ( percentage / 100.0 )
    @player_state.seconds_offset = second
    @player_state.play_start = DateTime.now
    ARUtils.save_cmdline(@player_state)
  end

  # Delete songs and move them to the trashcan folder
  # [+params[:songs_ids]+] Array of Song ids to destroy
  def delete_songs(params)

    ids = params[:songs_ids]

    # Check if the current playing song will be deleted:
    @player_state = PlayerState.load_state
    stopped = false
    if @player_state.play_list_song && ids.include?( @player_state.play_list_song.song.id )
      stopped = stop
      remove_song_from_state
    end

    # Execute the deletion
    editor = SongsEditor.new( ids )
    settings = Setting.get_settings
    editor.destroy_songs(settings)
    editor.purge_old_artists_albums

    # Restore the play state
    if stopped
      start
    end

    return editor.edition_result
  end

  # Delete a radio
  # [params[:radio_ids]+] Array of Radio ids to destroy
  # [+returns+] A CmdResult with the result
  def delete_radio(params)

    ids = params[:radio_ids]
    # Check if the current playing radio will be deleted:
    @player_state = PlayerState.load_state
    stopped = false
    if @player_state.radio && ids.include?( @player_state.radio.id )
      stopped = stop
      @player_state.radio = nil
      ARUtils.save_cmdline( @player_state )
    end

    # Execute the deletion
    Radio.find(ids).each { |r| r.destroy }

    # Restore the play state
    if stopped
      start
    end

    return CmdResult.new
  end

  # Change the speakers play mode (radio or mp3)
  # [+params[:mode]+] The new play mode. It can be
  # PlayerState::SOURCE_FILE_SONGS or PlayerState::SOURCE_RADIO. If it does
  # is not specified, the current mode will be switched to the other
  def change_mode(params = nil)

    if !params || !params[:mode]
      # Switch current mode
      if @player_state.mode == PlayerState::SOURCE_FILE_SONGS
        new_mode = PlayerState::SOURCE_RADIO
      else
        new_mode = PlayerState::SOURCE_FILE_SONGS
      end
    else
      # Set the parameter mode
      new_mode = params[:mode].to_i
    end
    return if @player_state.mode == new_mode

    stopped = stop
    @player_state.mode = new_mode
    @player_state.save
    if stopped
      start
    end

  end

  ###########################################################
  private
  ###########################################################

  # Remove the current song from the player state
  # [+returns+] The current PlayListSong
  def remove_song_from_state
    current_song = @player_state.play_list_song
    @player_state.play_list_song = nil
    ARUtils.save_cmdline(@player_state)
    return current_song
  end

  def restore_song_to_state(current_song)
    @player_state = PlayerState.load_state
    @player_state.play_list_song = current_song
  end

  # Change the current song, to previous or next
  # [+direction+] Direction to change the song, :forward or :backward
  def changeCurrentSong(direction)
    if !started?
      start
      return
    end

    stop

    if @player_state.mode == PlayerState::SOURCE_RADIO
      # Get the next radio
      @player_state.radio = Radio.next_radio( @player_state.radio , direction )
    else
      # Get the current song index
      @player_state.play_list_song = PlayList.reproduction_queue
        .next_song(@player_state.play_list_song , direction)
    end

    # Play the next song
    start
  end

  # Scan the root directory (@settings.music_dir_path) to search music files
  # [+clean+] True if the database should be entirely rebuild
  # [+returns+] A CmdResult with info of the operation execution
  def searchMusicFiles(clean = false)

    # Execute the search
    db_generation = DbGeneration.new( @settings )
    db_generation.parse_directory( clean )

    return CmdResult.new(:success, 'Music changes search started')

  end

  # Main worker thread entry
  # [+queue+] The reproduction queue
  def worker_thread(queue)
    begin
      puts 'Worker thread started'

      # Infinite loop
      loop do
        if @player_state.mode == PlayerState::SOURCE_FILE_SONGS
          # Play mp3 file
          @song_player.play( @player_state.play_list_song.song.full_path(@settings) , true )
        else
          # Play radio URL
          @song_player.play_url( @player_state.radio.streaming_url )
        end
        # Get the next song/radio to play
        if !next_song(queue)
          return
        end
      end

    rescue
      Log.log_last_exception
      @player_state.save_stop
      return "Error: #{$!.message}"
    end
  end

  def get_next_play_list_song(queue, play_list_song_id)
    case play_list_song_id
      when FIRST_SONG then
        return queue.first_song
      when NEXT_SONG then
        return queue.next_song(@player_state.play_list_song)
      when LAST_PLAYED_SONG then
        # Check the song still on the playlist. Otherwise, play from the start:
        return queue.start_song(@player_state.play_list_song)
      else
        # play_list_song_id contains the id of the song to play:
        return queue.start_song_id(play_list_song_id)
    end
  end

  def get_next_radio(radio_id)
    case radio_id
      when FIRST_SONG then
        return Radio.first
      when NEXT_SONG then
        return Radio.next_radio( @player_state.radio )
      when LAST_PLAYED_SONG then
        # Check the radio stills. Otherwise, play the first one:
        return Radio.start_radio( @player_state.radio )
      else
        # radio_id contains the id of the radio to play:
        return Radio.start_radio_id( radio_id )
    end
  end

  # Set the next or first song to play on @player_state.play_list_song
  # [+queue+] The PlayList with the reproduction queue
  # [+play_list_song_id+] Integer with the id of the first PlayListSong to play, or
  # LAST_PLAYED_SONG, or FIRST_SONG, or NEXT_SONG
  # [+returns+] True if there is a next song to play
  def next_song(queue, play_list_song_id = NEXT_SONG)

    if @player_state.mode == PlayerState::SOURCE_FILE_SONGS
      # Get the next play list song
      @player_state.play_list_song = get_next_play_list_song( queue , play_list_song_id )
      if !@player_state.play_list_song
        @player_state.save_stop
        puts "There is no song to play"
        return false
      end
    else
       # Get the next radio
       @player_state.radio = get_next_radio(play_list_song_id)
       if !@player_state.radio
         @player_state.save_stop
         puts "There is no radio to play"
         return false
       end
    end

    # Save the player state
    result = @player_state.save_playing
    return true

  end

end
