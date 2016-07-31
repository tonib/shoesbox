# Stores a running task on background
class Task < ActiveRecord::Base

  ###################################################
  # ATTRIBUTES
  ###################################################

  ##
  # :attr_accessor: name
  # Task name (length = Constants::NAME_MAX_LENGTH)

  ##
  # :attr_accessor: status
  # Text with the task status (length = Constants::NAME_MAX_LENGTH)

  ###################################################
  # MEMBERS
  ###################################################

  # Update the status and save
  def update_status(status)
    self.status = status
    save
  end

  # Run a task on background
  # [+task_name+] The task name
  # [+yield task+] The running Task
  def self.do_task(task_name)

    # Create the task on db
    task = Task.new
    task.name = task_name
    task.save

    # Run the task on background
    Thread.new do
      begin
        yield task
      rescue
        Log.log_last_exception("Error running '#{task_name}'")
      ensure
        task.destroy
      end
    end

  end

end
