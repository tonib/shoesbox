
# Albums resource controller
class AlbumsController < MusicBaseController

  # Suggest artists and albums names on searches
  include SuggestModule

  # Support zip download
  include ZipSongsModule

  PAGE_SIZE = 100

  # Albums list page
  def index
    @albums_count = Album.all.count
    load_albums_page
  end

  # Load the next page of artists
  def load_page
    respond_to do |format|
      format.html do
        load_artists_page
        render '_artist_rows' , layout: false
      end
    end
  end

  # Show the album
  def show
    @album = Album.find(params[:id])
    @album_songs = SongsSearch.new
    @album_songs.album_id = @album.id
    @album_songs.columns_order = ['songs.track' , 'songs.name']
    @settings = Setting.get_settings
  end

  # Edit the album
  def edit
    @album = Album.find(params[:id])
  end

  # Update the album
  def update
    @album = Album.find(params[:id])
    if @album.update(params.require(:album).permit(:name, :artist_name, :year))
      @album.update_mp3_files( Setting.get_settings )
      redirect_to @album
    else
      render 'edit'
    end
  end

  # Load the next page of albums
  def load_page
    respond_to do |format|
      format.html do
        load_albums_page
        render '_album_rows' , layout: false
      end
    end
  end

  # Action to suggest names on the filter
  def suggest
    suggest_classes( [ Album , Artist ] )
  end

  # Get available song ids from the request parameters.
  # (Overrides def on MusicBaseController)
  # [+returns+] Array of songs ids
  def get_selected_song_ids
    return get_songs_column( 'songs.id' )
  end

  # Returns an array with the relative path of the selected songs
  # (Overrides def on MusicBaseController)
  def get_selected_paths
    return get_songs_column( :path )
  end

  ###############################################
  protected
  ###############################################

  def get_songs_column( column )

    # Get the album ids
    albums_ids = get_base_relation
    albums_ids = albums_ids.where( id: params[:albumid] ) if params[:albumid] != 'all'
    albums_ids = albums_ids.pluck( 'albums.id' )

    # Get the songs relation
    relation = Album.all
      .joins( :songs )
      .where( id: albums_ids )
      .order( :name )

    # At the artist show page we can filter by the artist, so here is it:
    if params[:filter] && params[:filter][:artistid]
      relation = relation.where( 'songs.artist_id' => params[:filter][:artistid] )
    end

    # Get the column
    return relation.pluck( column )
  end

  def get_base_relation

    # Get filter parameters
    p = params[:filter] ? params[:filter] : params

    relation = Album.all
      .joins( { songs: :artist } )
      .group( :id , :name )
      .order( :name )

    # Filters
    p[:text_filter]  = "" if !p[:text_filter]
    if !p[:text_filter].empty?
      like_text = '%' + p[:text_filter] + '%'
      relation = relation.where('albums.name like ? or artists.name like ?' ,
        like_text , like_text)
    end

    p[:show_uncomplete] = p[:show_uncomplete] ? "true" : "false"
    if p[:show_uncomplete] == "false"
      relation = relation.having(
        'count(songs.id) >= 3 OR ( count(songs.id) = 1 AND sum(songs.seconds) > 1800 )')
    end

    return relation
  end

  def load_albums_page

    @albums = get_base_relation

    # Pagination
    params[:page_index] = 0 if !params[:page_index]
    page_index = params[:page_index].to_i
    @albums = @albums
      .limit(PAGE_SIZE)
      .offset(page_index * PAGE_SIZE)

    @albums = @albums
      .pluck( 'albums.id' , 'albums.name' , 'count(distinct artists.id)' , 'count(songs.id)' ,
        'min(artists.name)' , 'min(artists.id)' )
  end

end
