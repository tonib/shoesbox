
# Utility functions to prepare a zip of the selected songs
module ZipSongsModule

  # Maximum number of songs to download at the same time
  MAX_DOWNLOAD_SONGS = 200

  # Used to stream large zip files
  include ActionController::Live

  # Download multiple songs action
  def download_multiple

    # TODO: Handle all exceptions at root of this function
    # TODO: Handle single song download on SongsController

    # Get songs id (unique, on play lists they can be repeated)
    song_ids =  get_selected_song_ids
    song_ids.uniq!

    if song_ids.length > MAX_DOWNLOAD_SONGS
      raise Exception.new("Maximum number of songs to download is #{MAX_DOWNLOAD_SONGS}")
    end

    # TODO: Handle songs.length == 0

    # Get the songs
    settings = Setting.get_settings
    songs = Song.find( song_ids )
      .take(MAX_DOWNLOAD_SONGS + 1)

    # Create a temporal directory
    Dir.mktmpdir do |tmpdir|

      # Group songs by album
      songs_by_album = songs.group_by{ |s| s.album }
      songs_by_album.keys.each do |album|
        create_album_folder( settings, tmpdir, album , songs_by_album[album] )
      end

      # Get the pipe of the zip sdt output
      io = zip_directory_popen( tmpdir )
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

  end

  ######################################
  protected
  ######################################

  # Get an unused file name
  def get_unused_path(parent_dir, dir_name)
    cnt = 0
    path = File.join( parent_dir , dir_name )
    while File.exist?( path )
      cnt += 1
      path = File.join( parent_dir , dir_name + '-' + cnt.to_s )
    end
    return path
  end

  def create_album_folder(settings, tmpdir, album , songs)

    # Create subdirectory for album
    album_path = get_unused_path( tmpdir , ImagesModule.safe_file_name(album.name, true) )
    FileUtils::mkdir_p album_path

    # Create symbolic links on the album directory, without duplicate names
    songs.each do |s|
      source_path = s.full_path(settings)
      destination_path = get_unused_path( album_path , File.basename(s.path) )
      File.symlink(source_path, destination_path)
    end

  end

  def zip_directory_popen(directory)

    parent_dir = File.dirname(directory)
    dir_name = File.basename(directory)

    # "-Z store" == Do not compress
    # "-" == Write on the sdtout
    # "-r" == Recursive
    cmd = "cd #{Shellwords.escape(directory)} && zip -Z store  -r - *"

    # Execute the command and return the pipe
    puts cmd
    return IO.popen(cmd)

  end

end
