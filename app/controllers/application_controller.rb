
# Base controller
class ApplicationController < ActionController::Base

  # Value for cookie 'mode' for streaming mode
  STREAMING_MODE = 'streaming'

  # Value for cookie 'mode' for play on speakers mode
  PLAY_ON_SPEAKERS_MODE = 'speakers'

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # Uncomment this to enable MiniProfiler on production
  # before_action do
  #     Rack::MiniProfiler.authorize_request
  # end

  # The current player state. It can be a PlayerState or a PlayerStateStreaming
  attr_accessor :player_state

  # The current playing Song. It can be null if no song is playing
  attr_accessor :current_song

  # Error handling
  if Rails.env.production?
    unless Rails.application.config.consider_all_requests_local
      rescue_from Exception, with: :render_500
      rescue_from ActionController::RoutingError, with: :render_404
      rescue_from ActionController::UnknownController, with: :render_404
      rescue_from ActiveRecord::RecordNotFound, with: :render_404
    end
  end

  # Render a 'page not found' page
  def render_404(exception)
    @not_found_path = exception.message
    respond_to do |format|
      format.html { render template: 'errors/not_found',
                    layout: 'layouts/application', status: 404 }
      format.all { render nothing: true, status: 404 }
    end
  end

  # Render a error page
  def render_500(exception)
    @error_message = exception.message
    @stack_trace = exception.backtrace.join("\n")
    Log.log_exception(exception)
    respond_to do |format|
      format.html { render template: 'errors/internal_server_error',
                    layout: 'layouts/application', status: 500 }
      format.all { render nothing: true, status: 500}
    end
  end

  # Get the current play list
  # [+returns+] The current PlayList
  def current_play_list
    return @play_list if @play_list
    load_player_state
    @play_list = @player_state.play_list
    return @play_list
  end

  # Ensures the @player_state and @current_song members are loaded
  # [+force_reload+] If it's true, the state will be reloaded.
  def load_player_state(force_reload = false)
    return if !force_reload && @player_state
    @player_state = current_player_state
    if @player_state.playing? && @player_state.play_list_song
      @current_song = @player_state.play_list_song.song
    end
  end
  helper_method :load_player_state

  # Get the player state from the current request cookies
  # [+returns+] The current player state. It can be a PlayerState or a
  # PlayerStateStreaming
  def current_player_state

    mode = cookies[:mode]
    if !mode
      mode = PLAY_ON_SPEAKERS_MODE
    end

    puts "*** current_player_state.mode = #{mode.inspect}"
    if mode == STREAMING_MODE
      # Streaming mode
      puts "*** Playing streaming"
      ps = PlayerStateStreaming.new(cookies)
    else
      # Play on server speakers mode
      puts "*** Playing on speakers"
      ps = PlayerState.load_state
    end

    puts "*** Playing #{ps.mode == PlayerState::SOURCE_FILE_SONGS ? 'MP3' : 'Radio'}"
    return ps

  end

end
