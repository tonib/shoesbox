
# Utility functions to prepare a zip of the selected songs
module ZipSongsModule

  # Maximum number of songs to download at the same time
  MAX_DOWNLOAD_SONGS = 500

  # Used to stream large zip files
  include ActionController::Live

  # Download multiple songs action
  def download_multiple

    begin

      # Get songs id (unique, on play lists songs can be repeated)
      song_ids =  get_selected_song_ids
      song_ids.uniq!

      if song_ids.length > MAX_DOWNLOAD_SONGS
        raise "Maximum number of songs to download is #{MAX_DOWNLOAD_SONGS}"
      end

      if song_ids.length == 1 && controller_name == 'songs'
        # Special case. Download the mp3 file directly
        params[:song_id] = song_ids[0]
        download
        return
      end

      if song_ids.length == 0
        # Nothing to do
        raise "There are no songs to download"
      end

      # Get the songs
      settings = Setting.get_settings
      songs = Song
        .joins(:artist, :album)
        .find( song_ids )
        .take(MAX_DOWNLOAD_SONGS + 1)

      # Create a temporal directory
      Dir.mktmpdir do |tmpdir|

        # Group songs by album
        songs_by_album = songs.group_by{ |s| s.album }

        if songs_by_album.keys.length == 1
          # There is a single album: Create songs on the root
          songs = songs_by_album[songs_by_album.keys[0]]
          create_album_folder( settings, tmpdir, nil , songs )
        else
          # Create subdirectories for each album
          songs_by_album.keys.each do |album|
            create_album_folder( settings, tmpdir, album , songs_by_album[album] )
          end
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

    rescue
      Log.log_last_exception
    end

  end

  ######################################
  protected
  ######################################

  # Get an unused file name
  # [+parent_dir+] Directory where to search the unused file name
  # [+file_name+] File / directory desired on parent_dir
  # [+returns+] The full unused path
  def get_unused_path(parent_dir, file_name)
    cnt = 0
    path = File.join( parent_dir , file_name )
    while File.exist?( path )
      cnt += 1
      path = File.join( parent_dir , file_name + '-' + cnt.to_s )
    end
    return path
  end

  # Create symbolic links to a set of songs on a directory
  # [+settings+] Application Setting object
  # [+tmpdir+] Absolute directory path where create the symbolic links to songs
  # [+album+] The Album owner of the songs. nil if there is no album
  # [+songs+] A Song collection to link on tmpdir
  def create_album_folder(settings, tmpdir, album , songs)

    if !album || songs.length == 1
      # There is no album, or there is a single song on the album.
      # Do not create a new subdirectory
      album_path = tmpdir
    else
      # Create subdirectory for album
      subdir_name = album.name

      # Check if there is a single artist for the album:
      songs_by_artist = songs.group_by{ |s| s.artist }
      if songs_by_artist.length == 1
        subdir_name = songs_by_artist.keys[0].name + '-' + subdir_name
      end

      subdir_name = ImagesModule.safe_file_name( subdir_name , true )
      album_path = get_unused_path( tmpdir , subdir_name )
      FileUtils::mkdir_p album_path
    end

    # Create symbolic links on the album directory, without duplicate names
    songs.each do |s|
      source_path = s.full_path(settings)
      destination_path = get_unused_path( album_path , File.basename(s.path) )
      File.symlink(source_path, destination_path)
    end

  end

  # Run the linux zip command to compress a directory
  #[+directory+] The directory to compress
  #[+returns+] An IO object with the zip sdtout to compress the directory
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
