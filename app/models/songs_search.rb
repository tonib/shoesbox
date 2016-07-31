require_relative '../../lib/active_record_utils/arutils.rb'

# Perform a song search over a PlayList or the Song table
class SongsSearch

  # Index of the song id
  IDX_SONG_ID = 0
  # Index of the artist name
  IDX_ARTIST_NAME = 1
  # Index of the album name
  IDX_ALBUM_NAME = 2
  # Index of the song name
  IDX_SONG_NAME = 3
  # Index of the song length (in seconds)
  IDX_SONG_LENGTH = 4
  # Index of the artist id
  IDX_ARTIST_ID = 5
  # Index of the album id
  IDX_ALBUM_ID = 6
  # Index of the song path
  IDX_SONG_PATH = 7
  # Index of the song path
  IDX_TRACK = 8
  # Index of the play list song id. This column is optional (see initialize)
  IDX_PLAYLIST_ID = 9
  # Index of the song genre (extra column)
  IDX_GENRE = 10
  # Index of the song bit rate (extra column)
  IDX_BITRATE = 11
  # Index of the song file size (extra column)
  IDX_FILE_SIZE = 12

  # Filter by artist id ( integer or array of integers )
  attr_accessor :artist_id

  # Filter by album name
  attr_accessor :album_name

  # Filter by album id
  attr_accessor :album_id

  # Filter by text
  attr_accessor :text

  # Filter by song ids ( array of integers )
  attr_accessor :song_ids

  # Filter by play list songs ids ( array of integers )
  attr_accessor :play_list_song_ids

  # Number of records by page to fetch. If =0, all songs will be retrieved
  attr_accessor :page_size

  # Only applies if page_size <> 0. Index of the page to fetch
  attr_accessor :page_index

  # Array with columns order to sort the songs. The default order is by
  # artist name, album and track
  attr_accessor :columns_order

  #Boolean. True if all song columns should be retrieved (path, seconds, etc)
  attr_accessor :select_extra_columns

  # Constructor
  # [+play_list+] The PlayList where search. If
  # it's nil, the search will performed overt the Song table
  def initialize(play_list = nil)
    @play_list = play_list
    @page_index = 0
    @select_extra_columns = false
  end

  # True if the song search belongs to a PlayList
  def is_playlist
    return @play_list != nil
  end

  def set_play_list_song_ids(ids)
    if @play_list && ids && ids != 'all'
      @play_list_song_ids = ids.map { |x| x.to_i }
    end
  end

  def set_song_ids(ids)
    if ids && ids != 'all'
      @song_ids = ids.map { |x| x.to_i }
    end
  end

  # Apply a filter to the song search.
  # [+filter+] Hash with optional keys :artist_id, :album_name, :text. It can
  # be nil
  def apply_filter(filter)
    return if !filter

    # It can be the artist id or an array of ids
    @artist_id = filter[:artistid] if filter[:artistid]
    @artist_id = @artist_id.is_a?(Array) ? @artist_id.map { |x| x.to_i } : @artist_id.to_i

    set_song_ids( filter[:songid] )
    set_play_list_song_ids( filter[:play_list_song_ids] )

    @album_id = filter[:album_id].to_i if filter[:album_id]
    @album_name = filter[:album_name] if filter[:album_name]
    @text = filter[:text] if filter[:text]
  end

  # Get the songs count grouped by album
  # [+returns+] Array of [album.id , album.name , count_of_songs]
  def songs_by_album
    return @count_by_album if @count_by_album

    return get_base_relation(true, false)
      .group('albums.id')
      .order('albums.name')
      .pluck('albums.id' , 'albums.name' , 'count(*)')

  end

  # Get the page of songs found
  def songs_found
    get_songs
    return @songs
  end

  # Get the number of different artists on the songs found
  def n_artists
    if ! @n_artists_found
      @n_artists_found = songs_found
        .group_by{ |s| s[IDX_ARTIST_ID] }
        .length
    end
    return @n_artists_found
  end

  # Enumerates the Song items of this set
  # [+yields+] An array with the songs fields. See IDX_* for fields mean.
  def each
    songs_found.each{ |song| yield song }
  end

  # Get the row id. It can be the Song id or the PlayListSong id
  # [+returns+] The PlayListSong id if is_playlist was set on initialize.
  # Otherwise it return the Song id
  def song_set_id(song_row)
    if @play_list
      return "play_#{song_row[IDX_PLAYLIST_ID]}"
    else
      return "song_#{song_row[IDX_SONG_ID]}"
    end
  end

  # Get a play list song id as string
  def play_list_song_id(song_row)
    @play_list ? song_row[IDX_PLAYLIST_ID] : nil
  end

  # Return true if the query was paginated and there is more results
  def more_songs
    get_songs
    return @page_size && @songs.count == @page_size
  end

  # Get the shared folder where the songs of the result are place
  # [+settings+] The Setting object with the configuration
  # [+returns+] An array of arrays with each shared folder and the number of
  # songs inside that folder: [ [folder1, 10] , [folder2, 5] , ... ]
  # The array is sorted from the higher number of songs to the lower
  def get_shared_folders(settings)
    return songs_found
      .group_by{ |s| settings.shared_path( File.dirname( s[IDX_SONG_PATH] ) ) }
      .map do | shared_path , songs_array |
        if songs_array.length > 1
          [ shared_path , songs_array.length ]
        else
          [ settings.shared_path( songs_array[0][IDX_SONG_PATH] ) ]
        end
      end
      .sort_by { |a| a[0] }
      .reverse
  end

  # Get a file name for the current search
  # [+returns+] A file name for the search, without extension
  def search_file_name
    file_name = ''
    if @artist_id && @artist_id != 0
      artist_name = ARUtils.field( Artist , @artist_id , :name )
      file_name = artist_name if artist_name
    end
    if @album_id && @album_id != 0
      album_name = ARUtils.field( Album , @album_id , :name )
      file_name += ' - ' if ! file_name.empty?
      if album_name
        file_name += album_name
      end
    end
    file_name = 'songs' if file_name.empty?
    return ImagesModule.safe_file_name(file_name, true)
  end

  # Get an array with the selected Song's ids
  def get_songs_ids
    if @song_ids
      return @song_ids
    else
      return get_songs.map { |x| x[IDX_SONG_ID] }
    end
  end

  # Get an array with the selected PlayListSong's ids
  def get_play_list_song_ids
    return [] if !@play_list

    if @play_list_song_ids
      return @play_list_song_ids
    else
      return get_songs.map { |x| x[IDX_PLAYLIST_ID] }
    end
  end

  ############################################
  protected
  ############################################

  def fomat_count_search(result, id_index, name_index, count_index)
    result_formatted = []
    total_count = 0
    result.each do |x|
      result_formatted << [ x[id_index] , "#{x[name_index]} (#{x[count_index]})" ]
      total_count += x[count_index]
    end
    return [ result_formatted , total_count ]
  end

  # Load and return the @songs property (the filtered songs)
  def get_songs
    return @songs if @songs

    @songs = get_base_relation(true, true)
    if @play_list
      @songs = @songs.order( 'play_list_songs.song_order' )
    else
      if @columns_order
        @songs = @songs.order(@columns_order)
      end
    end

    # Paginate if it's needed
    if @page_size
      @songs = @songs
        .limit(@page_size)
        .offset(@page_index * @page_size)
    end

    # Get columns
    columns = [ 'songs.id' , 'artists.name' , 'albums.name' ,
      'songs.name' , 'songs.seconds' , 'artists.id' , 'albums.id' ,
      'songs.path' , 'songs.track' ]
    if is_playlist
      columns << 'play_list_songs.id'
    elsif @select_extra_columns
      # Add padding for corect extra columns indices
      columns << '0'
    end
    if @select_extra_columns
      # Add extra columnds
      columns = columns + [ 'songs.genre' , 'songs.bitrate' ,
        'songs.file_size' ]
    end

    @songs = @songs.pluck( *columns )
    return @songs
  end

  # Get the Relation for the search
  # [+filter_by_artist+] true if the Relation should be filtered by artist
  # [+filter_by_text+] true if the Relation should be filtered by text
  # [+returns+] The search Relation
  def get_base_relation(filter_by_artist, filter_by_text)

    # Join tables
    if @play_list
      relation = @play_list
        .play_list_songs
        .includes(:song , { :song => [ :album , :artist ] } )
    else
      # 1st try
      #relation = Song.all
      #  .includes( :album , { :album => :artist } )

      # 2 try
      #relation = Artist.all.joins( albums: :songs )

      # third. Mysql is not smart enought
      # relation = Artist.all
      #   .joins('INNER JOIN `albums` FORCE INDEX ( index_albums_on_artist_id_and_name ) ON `albums`.`artist_id` = `artists`.`id`')
      #   .joins('INNER JOIN `songs` FORCE INDEX ( index_songs_on_album_id_and_track_and_name_and_path ) ON `songs`.`album_id` = `albums`.`id`')

      relation = Artist.all
        .from('artists FORCE INDEX ( index_artists_on_name )')
        .joins('INNER JOIN `songs` FORCE INDEX ( index_songs_on_artist_id_and_album_id_and_track_and_name ) ON `songs`.`artist_id` = `artists`.`id`')
        .joins('INNER JOIN `albums` ON `songs`.`album_id` = `albums`.`id`')
    end

    # Filters
    if filter_by_artist && @artist_id && @artist_id != 0
      relation = relation.where( 'artists.id' => @artist_id )
    end
    if @album_name && !@album_name.empty?
      relation = relation.where( 'albums.name = ?' , @album_name )
    end

    if @album_id && @album_id != 0
      relation = relation.where( 'albums.id' => @album_id )
    end

    # Search by text
    if filter_by_text
        relation = QueryText.apply_composite_query(@text, relation)
    end

    if @song_ids
      relation = relation.where( 'songs.id' => @song_ids )
    end

    if @play_list && @play_list_song_ids
      relation = relation.where( 'play_list_songs.id' => @play_list_song_ids )
    end

    return relation
  end

end
