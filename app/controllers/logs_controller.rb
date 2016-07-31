
# Work with logs controller
class LogsController < ApplicationController

  # Rercords on each page
  PAGE_SIZE = 100

  # Index page
  def index
    render_index
  end

  # Load the next page of logs
  def load_page
    load_logs_page
    respond_to do |format|
      format.html do
        render '_logs_rows' , layout: false
      end
    end
  end

  # Show details page
  def show
    @log = Log.find(params[:id])
  end

  # Clear the log action
  def clear
    Log.delete_all
    render_index
  end

  ########################################################
  protected
  ########################################################

  def render_index
    load_logs_page
    render 'index'
  end

  def load_logs_page

    @logs = Log.all.order( id: :desc )

    # Pagination
    params[:page_index] = 0 if !params[:page_index]
    page_index = params[:page_index].to_i
    @logs = @logs
      .limit(PAGE_SIZE)
      .offset(page_index * PAGE_SIZE)
  end

end
