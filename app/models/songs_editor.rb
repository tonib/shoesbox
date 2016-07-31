require_relative '../../lib/tools/file_system_utils.rb'

# Tool to edit / insert / update songs and keep database consistency
class SongsEditor

  # The current songs set
  attr_accessor :songs

  # True if there was errors
  attr_accessor :error_messages

  # Constructor
  # [+songs_ids+] Song ids to insert / update
  def initialize(songs_ids = nil)
    if songs_ids
      @songs = Song.includes(:artist , :album).find(songs_ids)
      @old_artists = @songs.map { |s| s.artist }.uniq
      @old_albums = @songs.map { |s| s.album }.uniq
    else
      @songs = []
      @old_artists = []
      @old_albums = []
    end
    @error_messages = []
  end

  # Set the artist name to all songs
  # [+artist_name+] The new artist name
  def set_artist_name(artist_name)
    artist_name = Artist.normalize_name( artist_name )
    new_artist = Artist.find_or_create_by( name: artist_name )
    @songs.each { |s| s.artist = new_artist }
  end

  # Set the album name to all songs
  # [+album_name+] The new album name
  def set_album_name(album_name)
    album_name = Album.normalize_name( album_name )
    new_album = Album.find_or_create_by( name: album_name )
    @songs.each { |s| s.album = new_album }
  end

  # Set the genre to all songs
  # [+genre+] The new genre name
  def set_genre(genre)
    @songs.each { |s| s.genre = genre }
  end

  # Saves changes on songs
  # [+settings+] application Setting's object
  # [+returns+] True if there was no errors
  def save_changes(settings)

    @songs.each do |song|
      if song.save
        # Update the mp3 file
        song.update_file(settings)
      else
        # Store error messages
        song.errors.full_messages.each { |msg| @error_messages << msg }
      end
    end

    return ! with_errors?
  end

  # Destroy selected songs
  # [+settings+] The Setting's application object
  def destroy_songs(settings)

    @songs.each do |s|
      begin
        # Be sure the folder exists:
        trashcan_dir_path = File.join( settings.trashcan_folder , s.dirname )
        if !Dir.exists? trashcan_dir_path
          FileUtils::mkdir_p(trashcan_dir_path)
          change_owner(trashcan_dir_path)
        end

        # Move the song to the trashcan directory
        original_path = s.full_path(settings)
        if File.exist?(original_path )
          trashcan_path = File.join( settings.trashcan_folder , s.path )
          FileUtils.mv( original_path , trashcan_path )
        end

        # Delete the song
        if !s.destroy
          s.errors.full_messages.each { |msg| @error_messages << msg }
        end
      rescue
        Log.log_last_exception
        @error_messages <<  $!.message
      end
    end

  end

  # Remove empty artists and albums
  def purge_old_artists_albums
    return if with_errors?
    @old_artists.each { |a| a.destroy if a.songs.empty? }
    @old_albums.each { |a| a.destroy if a.songs.empty? }
  end

  # True if there was errors
  def with_errors?
    return ! @error_messages.empty?
  end

  # Return a CmdResult with the edition result
  def edition_result
    if with_errors?
      result = CmdResult.new( :error , @error_messages.join("\n") )
    else
      result = CmdResult.new( :success , 'OK' )
    end
  end

end
