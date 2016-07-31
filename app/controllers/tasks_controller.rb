
# The Task controller
class TasksController < ApplicationController

  def index
    @tasks = Task.all.order( :created_at )
  end

end
