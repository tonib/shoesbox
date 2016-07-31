
load "#{Rails.root}/lib/music/client.rb"
load "#{Rails.root}/lib/music/cmd_result.rb"
load "#{Rails.root}/lib/active_record_utils/bulk_operation.rb"
load "#{Rails.root}/lib/active_record_utils/arutils.rb"

# Main page
class PlayerController < MusicBaseController

  include SuggestModule

  # Renders the player page
  def index
    render_index
  end

  # Executes a command on the music server
  # [+params[:cmd]+] The command to execute on the music server. +'refresh'+
  # to refresh the player state
  def music_cmd

    # The command 'refresh' does not execute any command: It only refresh
    # the player state on the view
    if params[:cmd] != 'refresh'

      # Execute the command
      result = execute_music_cmd_from_parms

      # Feedback the user?
      if result && ( result.status == :error || result.info )
        @toast = result
      end

      # Refresh the production queue?
      if params[:cmd] == 'remove_queue_songs'
         @refresh_queue = true
      end

    end

    # Render the response
    respond_to do |format|
      format.html { render_index }
      format.js do
        load_player_state
        load_reproduction_queue if @refresh_queue
      end
    end

  end

  def load_page
    load_page_template(load_reproduction_queue)
  end

  # Change the current play list
  # [+params[:play_list_id]+] The PlayList id to set
  def change_play_list

    list_id = params[:play_list_id].to_i
    puts "*** change_play_list.list_id: #{list_id.inspect}"

    if list_id == PlayList.reproduction_queue.id
      # Play mp3 on speakers
      puts "*** Set play mp3 on speakers"
      cookies.permanent[:mode] = PLAY_ON_SPEAKERS_MODE
      cookies.permanent[:source] = PlayerState::SOURCE_FILE_SONGS
      cookies.permanent[:play_list_id] = list_id
      # Send the new mode to the play server
      execute_music_cmd( :change_mode , { mode: PlayerState::SOURCE_FILE_SONGS } )

    elsif list_id == -1
      # Play radio on speakers
      puts "*** Set play radio on speakers"
      cookies.permanent[:mode] = PLAY_ON_SPEAKERS_MODE
      cookies.permanent[:source] = PlayerState::SOURCE_RADIO
      # Send the new mode to the play server
      execute_music_cmd( :change_mode , { mode: PlayerState::SOURCE_RADIO } )

    elsif list_id == -2
      # Play radio with streaming
      puts "*** Set play mp3 on streaming (#{STREAMING_MODE}.inspect)"
      cookies.permanent[:mode] = STREAMING_MODE
      cookies.permanent[:source] = PlayerState::SOURCE_RADIO

    else
      # Play mp3 on streaming
      puts "*** Set play mp3 on streaming (#{STREAMING_MODE}.inspect)"
      cookies.permanent[:mode] = STREAMING_MODE
      cookies.permanent[:source] = PlayerState::SOURCE_FILE_SONGS
      cookies.permanent[:play_list_id] = list_id
    end

    redirect_to action: 'index'
  end


  # Action to suggest names on the filter
  def suggest
    suggest_classes( [ Song , Artist , Album ] )
  end

  ##################################################################
  protected
  ##################################################################

  def get_filter_changed_response
    get_filter_changed_response_base(load_reproduction_queue, :queue)
  end
  helper_method :get_filter_changed_response

  def load_reproduction_queue
    load_player_state

    if @player_state.mode == PlayerState::SOURCE_RADIO
      # Playing radio
      return @radios if @radios
      @radios = Radio.all.order(:name)
      # Get the content of the artist images directory
      @images_list = ImagesModule.images_dir_list
      return @radios
    else
      # Playing files
      return @queue_songs if @queue_songs
      # Get the songs page
      @queue_songs = SongsSearch.new( current_play_list )
      @queue_songs.apply_filter(params[:filter] ? params[:filter] : params)
      @queue_songs.page_size = 100
      @queue_songs.page_index = params[:page_index].to_i if params[:page_index]
      return @queue_songs
    end

  end

  def render_index
    load_player_state

    # Selected value on the mode combo
    if !@player_state.is_streaming? && @player_state.mode == PlayerState::SOURCE_RADIO
      @play_list_id = -1
    elsif @player_state.is_streaming? && @player_state.mode == PlayerState::SOURCE_RADIO
      @play_list_id = -2
    else
      @play_list_id = @player_state.play_list.id
    end

    # Load reproduction queue
    load_reproduction_queue

    # Load play lists
    @play_lists = PlayList.all.order(:name).to_a

    # Get and remove the reproduction queue of the server speakers:
    speakers_pl = @play_lists.find{ |p| p.name == PlayList::REPRODUCTION_QUEUE_NAME }
    @play_lists.delete( speakers_pl ) if speakers_pl

    # Change streaming playlists description
    @play_lists.each { |p| p.name = "Streaming - '#{p.name}' play list" }

    # Add radio mode (streaming)
    radio_item = PlayList.new
    radio_item.id = -2
    radio_item.name = 'Streaming - Play radio'
    @play_lists << radio_item

    if speakers_pl
      speakers_pl.name = 'Server speakers - Play MP3'
      @play_lists << speakers_pl
    end

    # Add radio mode (speakers)
    radio_item = PlayList.new
    radio_item.id = -1
    radio_item.name = 'Server speakers - Play radio'
    @play_lists << radio_item

    render 'index'

  end

end
