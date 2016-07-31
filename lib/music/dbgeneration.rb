require 'pathname'
require 'i18n'

# Active record stuff
require 'active_record'
require_relative '../../app/models/constants'
require_relative '../../app/models/artist'
require_relative '../../app/models/album'
require_relative '../../app/models/song'
require_relative '../../app/models/task'
require_relative '../active_record_utils/arutils'
require_relative '../active_record_utils/bulk_operation'

# taglib-ruby gem (gem install taglib-ruby)
require 'taglib'

# Tool to generate the music database
class DbGeneration

  @@running_db_generation = false

  # Integer with the number of added songs to the database
  attr_reader :n_added_songs

  # Integer with the number of removed songs from the database
  attr_reader :n_removed_songs

  def self.initialize
    @@running_db_generation = false
  end

  # Constructor
  # [+settings+] application Settings with the music directory to parse
  def initialize(settings)
    @n_added_songs = 0
    @n_removed_songs = 0
    @wikipedia_cache = nil
    @settings = settings
  end

  # Parse a music directory searching song files
  # [+clean+] True if the entire database should be clean before do the parse
  def parse_directory(clean = false)

    throw 'There is a process already searching music' if @@running_db_generation

    Task.do_task('Searching music...') do |task|
      begin
        @@running_db_generation = true
        @task = task

        # Be sure directory exists
        raise "Music directory does not exist" if ! Dir::exist? @settings.music_dir_path

        # Clean the database
        clean_db if clean

        puts "Searching song files"

        time_start = Time.now

        read_songs_db
        search_deleted_songs
        search_new_songs
        purge_empty_elements
        time_end = Time.now

        puts "#{@songs.length} songs found in #{time_end - time_start} seconds"

        # Search new metadata
        meta = MetaGeneration.new(@settings)
        meta.search_artists

      ensure
        @@running_db_generation = false
      end
    end

  end

  ################################################
  protected
  ################################################

  # Clean songs related tables on database
  def clean_db

    puts "Caching wikipedia links"
    @wikipedia_cache = {}
    Artist.all
      .where('wikilink IS NOT NULL')
      .pluck( 'name' , 'wikilink' )
      .each { |result| @wikipedia_cache[ key_name(result[0]) ] = result[1] }

    puts "Cleaning db"
    PlayerState.delete_all
    PlayListSong.delete_all
    Song.delete_all
    Album.delete_all
    Artist.delete_all
  end

  # Creates the song in the db from the file tags
  # [+music_dir_path+] Pathname of the base music directory
  # [+path+] Pathname of the song file
  # [+returns+] The Song on the file. nil if the file cannot be readed
  def parse_file(music_dir_path , path)
    begin

      begin
        # Get the relative path of the file
        relative_path = path.relative_path_from( music_dir_path ).to_s
      rescue
        puts "File cannot be readed. Wrong file name?: #{path.to_s}"
        return nil
      end

      # Do nothing if the song is already stored
      return nil if @songs[relative_path]

      absolute_path = path.to_s
      TagLib::MPEG::File.open( absolute_path ) do |file|
        # Create the song
        song = Song.new
        song.fill( relative_path , file , File.size(absolute_path) )

        # Get the artist and album
        song.artist = get_artist( file.tag.artist )
        if !song.artist
          puts "*** #{relative_path}: Artist not found"
          return nil
        end

        song.album = get_album( file.tag )
        if !song.album
          puts "*** #{relative_path}: Album not found"
          return nil
        end

        @songs[song.path] = song
        return song
      end
    rescue
      Log.log_last_exception("Error reading file #{path.to_s}")
      return nil
    end
  end

  def key_name(text)
    return I18n.transliterate(text).downcase.strip
  end

  def read_songs_db
    puts "Reading current songs db"

    # Cache of songs, path => Song
    @songs = {}
    Song.all.includes( :album , :artist ).each do |song|
      @songs[song.path] = song
    end

    # Cache of albums, album_name => Album
    @albums = {}
    Album.all.each do |album|
      @albums[key_name(album.name)] = album
    end

    # Cache of artists, artist_name => Artist
    @artists = {}
    Artist.all.each { |artist| @artists[key_name(artist.name)] = artist }

    puts "#{@songs.keys.count} songs found"
  end

  def search_deleted_songs
    puts "Searching deleted songs"
    @task.update_status('Searching deleted songs')

    # The trascan folder:
    trashcan_folder = @settings.trashcan_folder_normalized

    BulkOperation::bulk(:destroy) do |bulk|
      @songs.keys.each do |relative_path|

        full_path = File.join( @settings.music_dir_path , relative_path )

        delete_song = false
        if !File.exist? full_path
          delete_song = true
        elsif full_path.start_with?( trashcan_folder )
          delete_song = true
        end

        if delete_song
          # Deleted song from hash and db
          song = @songs.delete(relative_path)
          puts "#{song.to_s} deleted"
          bulk << song
          @n_removed_songs += 1
        end

      end
    end

  end

  def search_new_songs
    puts "Searching new songs"
    @task.update_status('Searching new songs')

    # The trascan folder:
    trashcan_folder = @settings.trashcan_folder_normalized

    # Bulk db operations
    n_new_songs = BulkOperation::bulk(:insert, Song) do |bulk|
      # Search mp3 files
      base_path = Pathname.new( @settings.music_dir_path )
      base_path.find do |path|

        # Only mp3 files:
        next if path.extname.downcase != ".mp3"

        # Ignore songs on trashcan folder:
        next if path.to_s.start_with?( trashcan_folder )

        song = parse_file(base_path , path)
        if song
          bulk << song
          @n_added_songs += 1
        end
      end
    end
    puts "#{n_new_songs} new songs found"
  end

  def purge_empty_elements
    puts "Deleting empty artists / albums"

    BulkOperation::bulk(:destroy) do |bulk|
      # Get the songs
      songs_alive = @songs.values

      # Get albums with some song:
      albums_alive = songs_alive.collect{ |s| s.album }.uniq

      # Delete albums with no songs
      ( @albums.values - albums_alive ).each do |album|
        puts "Deleting album #{album.to_s}"
        bulk << album
      end

      # Get artists with some song
      artists_alive = songs_alive.collect{ |s| s.artist }.uniq
      # Delete artists with no albums
      ( @artists.values - artists_alive ).each do |artist|
        puts "Deleting artist #{artist.to_s}"
        bulk << artist
      end
    end

  end

  def get_artist(artist_name)

    # Check if the artist already has been created
    artist_name = Artist.normalize_name(artist_name)
    key = key_name(artist_name)
    return @artists[key] if @artists.key?(key)

    # Check if the wikilinks cache exists
    wikilink = nil
    if @wikipedia_cache && @wikipedia_cache[key]
      wikilink = @wikipedia_cache[key]
    end

    puts "Creating artist #{artist_name}"
    artist = Artist.create(name: artist_name, wikilink: wikilink)
    return nil if !artist

    @artists[key] = artist
    return artist
  end

  def get_album(file_tags)

    if !file_tags
      album_name = Album::UNKNOWN_ALBUM_NAME
      album_year = 0
    else
      # Album name
      album_name = Album.normalize_name( file_tags.album )
      # Album year
      album_year = ( file_tags.year ? file_tags.year : 0 )
    end

    key = key_name(album_name)
    album = @albums[key]
    return album if album

    puts "Creating album #{album_name}"
    album = Album.new
    album.name = album_name
    album.year = album_year
    if !ARUtils::save_cmdline(album)
      return nil
    end

    @albums[key] = album
    return album
  end

end
