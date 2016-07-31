
load "#{Rails.root}/lib/music/cmd_result.rb"

# Base class for music command executor controllers
class MusicBaseController < ApplicationController

    # Execute a music server command
    # [+cmd+] Command to execute
    # [+cmd_params+] Parameters for the command
    # [+returns+] The CmdResult with the response from the server. It can
    # be null.
    def execute_music_cmd(cmd, cmd_params = {})

      puts "*** execute_music_cmd"
      load_player_state

      if !player_state.is_streaming? ||
         ( cmd == 'rescan_music' || cmd == 'clean_db' )
         puts "*** execute_music_cmd_remote"
        result = execute_music_cmd_remote(cmd, cmd_params)
      else
        puts "*** execute_music_cmd_streaming"
        result = execute_music_cmd_streaming(cmd, cmd_params)
      end

      # Ensure the player state is reloaded (it can be modified)
      load_player_state(true)

      return result
    end

    # Execute a music server command from parameters
    # [+returns+] The CmdResult with the response from the server. It can
    # be null.
    def execute_music_cmd_from_parms
      cmd = params[:cmd]
      return execute_music_cmd(cmd, get_cmd_parameters)
    end

    # Get play list ids from the request parameters
    # [+returns+] Array of songs ids
    def get_selected_play_list_song_ids
      get_selected_ids( :play_list_song_ids )
    end

    # Get available song ids from the request parameters
    # [+returns+] Array of songs ids
    def get_selected_song_ids
      get_selected_ids( :songid )
    end

    # Get an object with the info to re-render a songs filter and the first
    # songs page
    def get_filter_changed_response_base(songs_set, filter_id)

      # Render the response
      return {
        songs_page: render_to_string('shared/songs_table/_rows.html.erb' , layout: false,
          locals: { songs_set: songs_set } )
      }
    end

    def load_page_template(songs_set)
      respond_to do |format|
        format.html do
          render 'shared/songs_table/_rows' , layout: false, locals: { songs_set: songs_set }
        end
      end
    end

    # Get a file name for the request songs selection
    def selection_file_name( param_name )
      return 'songs' if !params[param_name]

      if params[param_name] == 'all'
        # Get all songs by filter
        songs_filter = get_songs_search_from_params
        return songs_filter.search_file_name
      else
        return 'songs'
      end
    end

    # Add songs to the reproduction queue
    def add_to_queue

      Task.do_task('Adding songs to queue...') do |t|
        # Get song ids to add
        song_ids = get_selected_song_ids

        # Add them to the reproduction queue
        queue = current_play_list
        queue.add_songs_ids(song_ids)
      end

      # Render to the response
      @toast = CmdResult.new( :success , "Adding songs started")
      render 'songs/music_cmd'
    end

    # Returns an array with the relative path of the selected songs
    def get_selected_paths
      return get_songs_search_from_params.songs_found.map { |s| s[SongsSearch::IDX_SONG_PATH] }
    end

    # Download a play list for the selected songs
    def download_playlist

      # Get the songs playlist
      settings = Setting.get_settings
      response_playlist = ''
      get_selected_paths.each do |song_path|
        response_playlist << settings.shared_path(song_path) << "\n"
      end

      # Send the file
      file_name = selection_file_name( :songid ) + '.m3u8'
      send_data response_playlist, type: 'audio/x-mpegurl' ,filename: file_name
    end

    ###################################################
    protected
    ###################################################

    # Execute a music server command on the remote server
    # [+cmd+] Command to execute
    # [+cmd_params+] Parameters for the command
    # [+returns+] The CmdResult with the response from the server. It can
    # be null.
    def execute_music_cmd_remote(cmd, cmd_params = {})

      begin
        client = Client.new
        client.connect
        result = client.send_command(cmd , cmd_params)

        # Clear SQL cache (DB may be changed)
        ActiveRecord::Base.connection.query_cache.clear

        return result
      rescue
        Log.log_last_exception
        return CmdResult.new( :error , $!.message )
      end

    end

    # Execute a music server command for the streaming player
    # [+cmd+] Command to execute
    # [+cmd_params+] Parameters for the command
    # [+returns+] The CmdResult with the response from the server. It can
    # be null.
    def execute_music_cmd_streaming(cmd, cmd_params = {})
      state = PlayerStateStreaming.new(cookies)
      @streaming_js_command , cmd_result = state.execute_cmd(self, cmd, cmd_params)
      return cmd_result
    end

    # Get a SongsSearch from the request parameters
    # [+returns+] The requested SongsSearch
    def get_songs_search_from_params

      params[:filter] = {} if !params[:filter]

      # Check if there is a play list filter on the parameters
      play_list_id = params[:filter][:play_list_id]
      if( play_list_id )
        play_list = PlayList.find( play_list_id )
      else
        play_list = nil
      end

      songs_filter = SongsSearch.new(play_list)
      songs_filter.apply_filter( params[:filter] )
      # Map id filters:
      songs_filter.set_song_ids( params[:songid] )
      songs_filter.set_play_list_song_ids( params[:play_list_song_ids] )

      return songs_filter
    end

    # Get songs / play list ids from the request parameters
    # [+param_name+] The request parameter with the songs ids. It can be
    # :play_list_song_ids or :songid
    # [+returns+] Array of songs ids
    def get_selected_ids(param_name)

      return nil if !params[param_name]

      songs_filter = get_songs_search_from_params
      return param_name == :songid ? songs_filter.get_songs_ids :
        songs_filter.get_play_list_song_ids

    end

    # Get the music commands from the parameters
    # [+returns+] Array with music command parameters
    def get_cmd_parameters

      cmd_params = {}

      # Get play list songs ids
      if params[:play_list_song_ids]
        cmd_params[:play_list_song_ids] = get_selected_play_list_song_ids
      end

      # Get available songs ids
      if params[:song_ids]
        cmd_params[:song_ids] = get_selected_song_ids
      end

      # Other parameters
      cmd_params[:play_list_song_id] = params[:play_list_song_id] if params[:play_list_song_id]
      cmd_params[:song_id] = params[:song_id] if params[:song_id]
      cmd_params[:radio_id] = params[:radio_id] if params[:radio_id]
      cmd_params[:volume] = params[:volume] if params[:volume]
      cmd_params[:percentage] = params[:percentage] if params[:percentage]

      return cmd_params
    end

end
