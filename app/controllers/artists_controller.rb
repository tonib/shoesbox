require 'music/meta_generation'

# Artists resource controller
class ArtistsController < MusicBaseController

  include SuggestModule

  # Number of artists to load by page
  PAGE_SIZE = 50

  # List artists action
  def index
    render_index
  end

  # Show the artist
  def show
    @artist = Artist.find(params[:id])
    @artist_songs = SongsSearch.new
    @artist_songs.artist_id = @artist.id
    @settings = Setting.get_settings
  end

  # Edit form
  def edit
    load_update
    # Do not allow to edit the unknown artist
    redirect_to artist_path(@artist) if @artist.name == Artist::UNKNOWN_ARTIST_NAME
  end

  # Update artist on db
  def update
    begin
      load_update
      old_name = @artist.name
      if @artist.update(artist_params)
        if old_name != @artist.name
          # Update the artist name on mp3 files
          @artist.update_mp3_files(Setting.get_settings)
          @artist.rename_image_files(old_name)
        end
        # Update the artist image if needed
        store_artist_image
      end
    rescue
      @artist.errors.add(:base , $!.message )
      Log.log_last_exception
    end

    check_errors_redirect(@artist.errors, 'edit')
  end

  # Search wikipedia suggestions
  # [+params[:artist_name]+] The artist name to search
  def search_wikipedia
    respond_to do |format|
      format.html do
        @wikipedia_search_text = params[:artist_name]
        meta = MetaGeneration.new(Setting.get_settings)
        @wikipedia_search = meta.search_text(@wikipedia_search_text, 10)
        render 'search_wikipedia.html', layout: false
      end
    end
  end

  # Get a wikipedia main image article
  # [+params[:wikipedia_url]+] The wikipedia article url
  def get_wikipedia_image
    respond_to do |format|
      format.js do
        meta = MetaGeneration.new(Setting.get_settings)
        wiki_url = URI.escape(params[:wikipedia_url])
        @wikipedia_image_url = meta.get_wikipedia_image_url(wiki_url)
      end
    end
  end

  # Join an artist to other
  def join
    @join_errors = ActiveModel::Errors.new(self)
    begin
      load_update
      target_artist = Artist.find(params[:dest_artist_id])
      @artist.join_to_other(Setting.get_settings, target_artist)
    rescue
      @join_errors.add(:base , $!.message)
      Log.log_last_exception
    end

    check_errors_redirect( @join_errors , 'edit')
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

  # Get available song ids from the request parameters (Overrides def on
  # MusicBaseController)
  # [+returns+] Array of songs ids
  def get_selected_song_ids
    return get_songs_relation.pluck( 'songs.id' )
  end

  # Returns an array with the relative path of the selected songs
  # (Overrides def on MusicBaseController)
  def get_selected_paths
    return get_songs_relation.pluck( :path )
  end

  ####################################
  protected
  ####################################

  def get_songs_relation
    relation = get_base_relation
    relation = relation.where( id: params[:artistid] ) if params[:artistid] != 'all'
    return relation
      .order( :name )
      .joins( :songs )
  end

  def load_update
    @artist = Artist.find(params[:id])
    @target_artists = Artist
      .where.not( id: params[:id] )
      .order( :name )
      .pluck( 'id' , 'name' )
  end

  def check_errors_redirect(errors, error_view)
    if errors.any?
      render error_view
    else
      redirect_to artists_path
    end
  end

  def get_base_relation
    # Get filter parameters
    p = params[:filter] ? params[:filter] : params

    relation = Artist.all
    if p[:text_filter] && !p[:text_filter].empty?
      relation = relation.where('artists.name like ?' , '%' + p[:text_filter] + '%')
    end
    return relation
  end

  def load_artists_page

    @artists = get_base_relation
      .select('artists.*, count(songs.id) as songs_count')
      .joins( :songs )
      .group( 'artists.id' )

    # Order
    params[:order] = 'count' if !params[:order] || params[:order] == ''
    if params[:order] == 'count'
      @artists = @artists.order('songs_count desc, artists.name')
    else
      @artists = @artists.order(:name)
    end

    # Pagination
    params[:page_index] = 0 if !params[:page_index]
    page_index = params[:page_index].to_i
    @artists = @artists
      .limit(PAGE_SIZE)
      .offset(page_index * PAGE_SIZE)

    # Get the content of the artist images directory
    @images_list = ImagesModule.images_dir_list
  end

  def render_index

    @sort_options =
      [ [ "name" , "Sort by name" ] , [ "count" , "Sort by number of songs" ] ]

    load_artists_page
    @artists_count = Artist.all.count
    render 'index'
  end

  # Update the artist image if needed
  # [+params[:new_image_url]+] The artist image url to save. Empty to do not
  # change the image
  def store_artist_image
    ArtistsController.store_image(self, @artist)
  end

  # Store an image for a radio / artist
  def self.store_image(controller, model_instance)
    begin
      url = controller.params[:new_image_url]
      return if url.empty?
      # Remove previous image
      model_instance.delete_image_files
      # Download the new image
      MetaGeneration.download_artist_image(model_instance, url)
    rescue
      model_instance.errors.add(:base , 'Error storing the image, ' + $!.message )
      Log.log_last_exception
    end
  end

  # Get the form parameters
  def artist_params
    params.require(:artist).permit(:name, :wikilink)
  end

end
