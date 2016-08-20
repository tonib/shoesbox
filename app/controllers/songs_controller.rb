require 'tempfile'
require 'csv'
load "#{Rails.root}/lib/tools/zip_file.rb"
load "#{Rails.root}/lib/music/client.rb"

# Work with available songs controller
class SongsController < MusicBaseController

  include SuggestModule

  # Used to stream large zip files (sooooo hard)
  include ActionController::Live

  # Maximum number of songs to download at the same time
  MAX_DOWNLOAD_SONGS = 200

  ###################################################
  # Actions
  ###################################################

  # Songs list
  def index
    @songs_count = Song.count
    load_songs
  end

  # Show the song
  def show
    render_show
  end

  # Edit a song
  def edit
    params[:songid] = []
    params[:songid] << params[:id]
    edit_multiple
    render'edit_multiple'
  end

  # Edit multiple songs
  def edit_multiple

    # Get songs to edit
    ids = get_selected_song_ids
    if ids.length > 100
      @errors = ActiveModel::Errors.new(self)
      @errors.add(:base , 'Maximum number of song to edit at same time is 100')
      ids = ids.take(100)
    end
    @songs = Song.find( ids )

    # Check what to update:
    if @songs.group_by{ |s| s.artist.id }.keys.length == 1
      @update_artist = true
      @artist_name = @songs[0].artist.name
    else
      @update_artist = false
      @artist_name = 'Various'
    end

    if @songs.group_by{ |s| s.album.id }.keys.length == 1
      @update_album = true
      @album_name = @songs[0].album.name
    else
      @update_album = false
      @album_name = 'Various'
    end

    if @songs.group_by{ |s| s.genre }.keys.length == 1
      @update_genre = true
      @genre = @songs[0].genre
    else
      @update_genre = false
      @genre = 'Various'
    end

  end

  # Update multiple songs
  def update_multiple

    songs_ids = params[:songs].keys.map { |k| k.to_i }
    editor = SongsEditor.new( songs_ids )

    # Do common changes
    editor.set_artist_name( params[:artist] ) if params[:update_artist]
    editor.set_album_name( params[:album] ) if params[:update_album]
    editor.set_genre( params[:genre] ) if params[:update_genre]

    # Do each song change
    editor.songs.each do |song|
      song_params = params[:songs][ song.id.to_s ]
      song.track = song_params[:track]
      song.name = song_params[:name]
    end

    # Save changes and purge albums / artists
    settings = Setting.get_settings
    editor.save_changes(settings)
    editor.purge_old_artists_albums

    if !editor.with_errors?

      # Fire the metadata search
      execute_music_cmd( :search_meta )

      if editor.songs.count == 1
        redirect_to song_path( editor.songs[0] )
      else
        redirect_to songs_path
      end
    else
      # TODO: Render errors
      render 'edit_multiple'
    end

  end

  # Load next songs page
  def load_page
    load_songs
    load_page_template(@songs)
  end

  # Executes a command on the music server
  def music_cmd
    result = execute_music_cmd_from_parms
    # Feedback the user
    if result
      result.info = "OK" if !result.info
      @toast = result
    end
    load_songs
    render 'music_cmd'
  end

  # Download one song action
  def download

    # Song info
    song = Song.find(params[:song_id])
    settings = Setting.get_settings

    # Default range to download (all the file)
    file_begin = 0
    file_end = song.file_size - 1

    # Get the range to download from the request
    if !request.headers["Range"]
      # Download the entire file
      status_code = "200 OK"
    else
      # Download a range
      puts "*** Request header: #{request.headers["Range"]}"
      status_code = "206 Partial Content"
      match = request.headers['range'].match(/bytes=(\d+)-(\d*)/)
      if match
        file_begin = match[1]
        file_end = match[2] if match[2] && !match[2].empty?
        puts "*** Requesting file range[#{file_begin.to_s}-#{file_end.to_s}]"
      end
      response.header["Content-Range"] = "bytes " + file_begin.to_s + "-" +
        file_end.to_s + "/" + song.file_size.to_s
    end

    # Common headers
    #response.header["Last-Modified"] = @media.file_updated_at.to_s < NOT AVAILABLE
    response.header["Cache-Control"] = "public, must-revalidate, max-age=0"
    response.header["Pragma"] = "no-cache"
    response.header["Accept-Ranges"]=  "bytes"
    response.header["Content-Transfer-Encoding"] = "binary"

    # File range to download
    offset = file_begin.to_i
    content_length = file_end.to_i - offset + 1
    response.header["Content-Length"] = content_length.to_s

    # Read the requested bytes range:
    song_path = song.full_path(settings)
    partial_content = IO.binread(song_path, content_length, offset)

    # Send the range
    send_data partial_content,
      :filename => File.basename(song.path),
      :type => 'audio/mpeg',
      #:disposition => "inline",
      :stream => true,
      :status => status_code

  end

  # Download multiple songs
  def download_multiple

    # Get the songs ids
    song_ids =  get_selected_song_ids
    if song_ids.length == 1
      params[:song_id] = song_ids[0]
      download
      return
    end

    # Get the songs paths
    settings = Setting.get_settings
    songs_paths = Song.find( song_ids ).take(MAX_DOWNLOAD_SONGS + 1)
      .map { |song| song.full_path(settings) }

    if songs_paths.length > MAX_DOWNLOAD_SONGS
      raise Exception.new("Maximum number of songs to download is #{MAX_DOWNLOAD_SONGS}")
    end

    # Get the pipe of the zip sdt output
    io = create_zip_file_popen( songs_paths )
    zip_pid = io.pid
    file_name = selection_file_name(:songid) + '.zip'

    self.content_type = 'application/zip'
    self.response.headers['Content-Disposition'] =
      "attachment; filename=\"#{file_name}\""

    # Stream the zip, to avoid delay and memory wasting
    begin
      # Write chunks of the zip file
      chunk_size = 2**20 * 4  # 4 MB
      until io.eof?
        response.stream.write( io.read( chunk_size ) )
      end
    rescue
      # Client disconnected is ok, don't log it
      Log.log_last_exception if ! $!.is_a?( ActionController::Live::ClientDisconnected )
      # Ensure zip execution is finished
      begin
        io.close
      rescue
      end
    ensure
      # Ensure the stream is closed
      response.stream.close
    end

  end

  # Action to delete multiple songs
  def delete_multiple

    begin
      # Do the deletion
      ids = get_selected_song_ids
      if ids.length > MAX_DOWNLOAD_SONGS
        raise "Maximum number of songs to delete is #{MAX_DOWNLOAD_SONGS}"
      end
      @toast = execute_music_cmd( :delete_songs , { songs_ids: ids } )
      # Refresh the displayed songs
      load_songs
    rescue
      Log.log_last_exception
      @toast = CmdResult.new( :error , $!.message )
    end

    # Render to the response
    render 'music_cmd'

  end

  # Action to delete a song
  def destroy
    result = execute_music_cmd( :delete_songs , { songs_ids: [ params[:id].to_i ] } )
    if result.status == :success
      redirect_to songs_path
    else
      render_show(result)
    end
  end

  # Action to suggest names on the filter
  def suggest
    suggest_classes( [ Song , Artist , Album ] )
  end

  # Action to download the selected songs as an Excel file
  def excel

    excel_songs = get_songs_search_from_params
    excel_songs.select_extra_columns = true
    excel_songs = excel_songs.songs_found.map { |s|
      [ s[SongsSearch::IDX_ARTIST_NAME] , s[SongsSearch::IDX_ALBUM_NAME] ,
        s[SongsSearch::IDX_TRACK] , s[SongsSearch::IDX_SONG_NAME] ,
        s[SongsSearch::IDX_SONG_PATH] , s[SongsSearch::IDX_SONG_LENGTH] ,
        s[SongsSearch::IDX_GENRE] , s[SongsSearch::IDX_BITRATE] ,
        s[SongsSearch::IDX_FILE_SIZE] ]
    }

    respond_to do |format|
      format.html
      format.csv do
        csv = CSV.generate do |csv|
          csv << [ "Artist", "Album", 'Track Number' , "Song" , "Path" ,
            "Length (Seconds)" , "Genre" , "Bitrate (Kb/s)" , "Size (bytes)" ]
          excel_songs.each do |s|
            # Check if the track number is empty:
            s[2] = nil if s[2] == 0
            csv << s
          end
        end
        send_data csv, type: 'text/csv', filename: 'songs.csv'
      end
    end

  end

  ###################################################
  protected
  ###################################################

  def render_show(result = nil)
    @settings = Setting.get_settings
    @song = Song.find(params[:id])
    if result != nil
      @errors = ActiveModel::Errors.new(@song)
      @errors.add(:base, result.info)
    end
    render 'show'
  end

  def get_filter_changed_response
    get_filter_changed_response_base(load_songs, :queue)
  end
  helper_method :get_filter_changed_response

  # Loads and it returns the current songs page
  def load_songs

    return @songs if @songs

    # Get the filter to apply
    filter_parms = ( params[:filter] ? params[:filter] : params )

    @songs = SongsSearch.new
    @songs.apply_filter(filter_parms)
    @songs.page_size = 100
    @songs.page_index = params[:page_index].to_i if params[:page_index]

    return @songs
  end

end
