require 'fileutils'
require 'taglib'
require_relative '../../lib/tools/file_system_utils.rb'

# Miscellaneous functions controller
class ToolsController < MusicBaseController

  # Post action to get a song from youtube
  def get_youtube

    @url = params[:url]
    @song_name = params[:song_name]
    @artist_name = Artist.normalize_name( params[:artist_name] )
    @album_name = Album.normalize_name( params[:album_name] )
    @track = params[:track].to_i

    # Validate
    @errors = ActiveModel::Errors.new(self)
    if params[:song_name].empty?
      @errors.add( :base , 'Song name cannot be empty')
    end
    if params[:url].empty?
      @errors.add( :base , 'URL cannot be empty')
    end
    if @errors.any?
      render 'youtube'
      return
    end

    # Get the destination filename:
    filename = @artist_name + '-' + @song_name
    filename = ImagesModule.safe_file_name(filename, true)

    settings = Setting.get_settings

    # Get the destination directory path:
    path = settings.youtube_folder
    if !path || path.empty?
      raise "Youtube downloads destination folder was not specified"
    end

    # Create the destination directory if it does not exists
    if !Dir.exists? path
      FileUtils::mkdir_p path
      change_owner(path)
    end

    path = File.join( path , filename )

    absolute_path = path + '.mp3'
    if File.exist?(absolute_path)
      @errors.add( :base , "File #{absolute_path} already exists")
      render 'youtube'
      return
    end

    # Run command line:
    o_path =  path + '.%(ext)s'
    puts o_path
    cmd = "youtube-dl --extract-audio --audio-format mp3 \"#{@url}\" -o \"#{o_path}\" 2>&1"
    @response = `#{cmd}`
    @response = cmd + "\n" + @response
    puts @response

    if $?.success?
      mp3_path = path + '.mp3'

      # Change ownership to "pi"
      change_owner(mp3_path)

      # Save the song to the database
      TagLib::MPEG::File.open(mp3_path) do |file|
        @song = Song.new
        relative_path = settings.relative_path_from_absolute(absolute_path)
        @song.fill( relative_path , file , File.size(absolute_path) )
        @song.artist = Artist.find_or_create_by( name: @artist_name )
        @song.album = Album.find_or_create_by( name: @album_name )
        @song.name = @song_name
        @song.track = @track
        if !@song.save
          @errors = @song.errors
        end
      end
      if !@song
        @errors.add( :base , "Song file #{absolute_path} not found")
      end
    else
      @errors.add( :base , 'Song download failed')
    end

    if !@errors.any?
      @song.update_file(settings)
      @errors = [ 'Song saved' ]
      @url = @song_name = @artist_name = @track = ''

      # Fire the metadata search
      execute_music_cmd( :search_meta )

    else
      @song = nil
    end

    render 'youtube'

  end

  # Action to get a table of duplicated songs
  def duplicated_songs

    # Songs with the same artist, album and name
    @repeated_songs = Song.all
      .joins( :album , :artist )
      .group( 'artists.name' , 'albums.name' , 'songs.name' )
      .having( 'count(*) > 1' )
      .order( 'artists.name' , 'albums.name' , 'songs.name' )
      .pluck( 'artists.name' , 'albums.name' , 'songs.name' , 'count(*)' )

    # Songs with with the same artist and name, one with no album and other
    # with one
    @repeated_no_album = Song.all
      .joins( :album , :artist )
      .joins('INNER JOIN songs s2 ON songs.name = s2.name AND ' +
        'songs.artist_id = s2.artist_id AND songs.album_id <> s2.album_id')
      .joins( 'INNER JOIN albums a2 ON s2.album_id = a2.id' )
      .where( 'albums.name = ?' , Album::UNKNOWN_ALBUM_NAME )
      .pluck( 'artists.name' , 'songs.name' , ' a2.name' )

    @short_songs = Song.all
      .joins( :album , :artist )
      .where( 'songs.seconds < 5' )
      .order( 'artists.name' , 'songs.name' , 'albums.name' )

    duplicated_wikilinks = Artist.all
      .where( "coalesce( artists.wikilink , '' ) <> ''" )
      .group( 'artists.wikilink' )
      .having( 'count(*) > 1' )
      .pluck( 'artists.wikilink' )

    @duplicated_artists = Artist.all
      .where( wikilink: duplicated_wikilinks )
      .order( :wikilink , :name )

  end

  # Display the readme action
  def readme
    txt = File.open(Rails.root.join('README.rdoc'), 'r').read
    @readme = RDoc::Markup::ToHtml.new(RDoc::Options.new).convert(txt)
  end

end
