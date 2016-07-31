
# Stream play lists controller
class PlayListsController < ApplicationController

  # Index page
  def index
    # Do not display the speakers playlist
    @play_lists = PlayList.all
      .where( 'name != ?' , PlayList::REPRODUCTION_QUEUE_NAME )
      .order(:name)
  end

  # Create new play list
  def new
    @play_list = PlayList.new
    render 'form'
  end

  # Save a new play list
  def create
    @play_list = PlayList.new(play_list_params)
    if @play_list.save
      redirect_to play_lists_path
    else
      render 'form'
    end
  end

  # Edit a play list
  def edit
    @play_list = PlayList.find(params[:id])
    render 'form'
  end

  # Update a play list
  def update
    @play_list = PlayList.find(params[:id])
    if @play_list.update(play_list_params)
      redirect_to play_lists_path
    else
      render 'form'
    end
  end

  # Delete a play list
  def destroy
    @play_list = PlayList.find(params[:id])
    if @play_list.destroy
      redirect_to play_lists_path
    else
      render 'form'
    end
  end

  # def show
  #   @play_list = PlayList.find(params[:id])
  # end

  ###############################################
  protected
  ###############################################

  def play_list_params
    params.require(:play_list).permit(:name)
  end

end
