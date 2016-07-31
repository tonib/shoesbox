require_relative '../../lib/music/meta_generation'

# Work with radios controller
class RadiosController < MusicBaseController

  include SpanishRadiosModule

  # Index page
  def index
    render_index
  end

  # Show a radio action
  def show
    @radio = Radio.find( params[:id] )
  end

  # Create new radio
  def new
    @radio = Radio.new
    render 'form'
  end

  # Save a new radio
  def create
    @radio = Radio.new( play_list_params )
    if @radio.save
      store_radio_image
    end
    check_errors_edit
  end

  # Edit a radio
  def edit
    @radio = Radio.find( params[:id] )
    render 'form'
  end

  # Update a radio
  def update
    @radio = Radio.find(params[:id])
    old_name = @radio.name
    if @radio.update(play_list_params)
      if old_name != @radio.name
        # Update the image file names
        @radio.rename_image_files(old_name)
      end
      store_radio_image
    end
    check_errors_edit
  end

  # Delete a radio
  def destroy
    result = execute_music_cmd( :delete_radio , { radio_ids: [ params[:id].to_i ] } )
    if result.status == :success
      redirect_to radios_path
    else
      @radio = Radio.find( params[:id] )
      @radio.errors.add(:base , result.info )
      render 'form'
    end
  end

  # Create some spanish radios
  def create_spanish_radios
    spanish_radios.each do |radio_info|
      if !Radio.where(name: radio_info[:name]).any?
        r = Radio.new
        r.name = radio_info[:name]
        r.streaming_url = radio_info[:streaming_url]
        r.web_url = radio_info[:web_url]
        r.save

        if radio_info[:image_url]
          # Try to save the radio image
          begin
            MetaGeneration.download_artist_image(r, radio_info[:image_url])
          rescue
            Log.log_last_exception
          end
        end
      end
    end
    redirect_to radios_path
  end

  ###############################################
  protected
  ###############################################

  def check_errors_edit
    if @radio.errors.any?
      render 'form'
    else
      redirect_to radios_path
    end
  end

  # Store the radio image
  def store_radio_image
    ArtistsController.store_image(self, @radio)
  end

  def play_list_params
    params.require(:radio).permit(:name, :streaming_url, :web_url)
  end

  def render_index
    @radios = Radio.all.order(:name)
    # Get the content of the artist images directory
    @images_list = ImagesModule.images_dir_list
    render 'index'
  end

end
