
load "#{Rails.root}/lib/music/client.rb"
load "#{Rails.root}/lib/music/cmd_result.rb"

# Application settings controller
class SettingsController < MusicBaseController

  # Edit form
  def edit
    @setting = Setting.get_settings
    render_edit
  end

  # Update settings on db
  def update

    ok = true
    # Save settings
    @setting = Setting.get_settings
    if @setting.update(settings_params)
      # Notify to the music server the settings change
      execute_music_cmd_check_error(@setting.errors , :reload_settings)
    end

    if @setting.errors.any?
      render_edit
    else
      redirect_to root_path
    end

  end

  # Speech form
  def speech
    @setting = Setting.get_settings
    @speech_errors = ActiveModel::Errors.new(self)
    execute_music_cmd_check_error( @speech_errors , :speech , { message: params[:speech_text] } )
    render_edit
  end

  # Clean and recalculate metadata action
  def recalculate_metadata
    @setting = Setting.get_settings
    @result = execute_music_cmd( :search_meta , { clean: true } )
    render 'command_result'
  end

  # Start the music service action
  def start_music_service
    execute_system_cmd('/etc/init.d/music_daemon start')
  end

  # Stop the music service action
  def stop_music_service
    execute_system_cmd('/etc/init.d/music_daemon stop')
  end

  # Shutdown the device action
  def shutdown
    execute_system_cmd('shutdown -h now')
  end

  # Mount my usb drive (ugly hack, i know)
  def mount_usb_drive
    execute_system_cmd('mount /home/pi/compartida/musica/discousb')
  end

  ################################################################
  protected
  ################################################################

  # Render the form in edit mode
  def render_edit
    @txt_disk_usage = `df`
    @txt_memory_usage = `free -m`

    # Get temperature
    begin
      @temperature = `cat /sys/class/thermal/thermal_zone0/temp`
      @temperature = @temperature.to_i / 1000.0
      @temperature = "#{@temperature} Cº"
    rescue
      Log.log_last_exception
      @temperature = '??? Cº'
    end

    # Available input devices:
    begin
      devs_dir = '/dev/input/by-id'
      if Dir.exists?(devs_dir)
        @input_devices = Dir
          .entries( devs_dir )
          .select { |d| !File.directory?(d) }
      else
        @input_devices = []
      end
    rescue
      Log.log_last_exception
      @input_devices = []
    end

    render 'edit'
  end

  def execute_system_cmd(cmd)
    result_text = `#{cmd} 2>&1`
    puts result_text
    result_text = "Ok" if result_text.empty? && $?.success?
    @result = CmdResult.new( $?.success? ? :success : :error , result_text )
    if !$?.success?
      Log.log_error("Error executing #{cmd}", result_text)
    end
    puts @result.inspect
    render 'command_result'
  end

  # Execute a command on the music server
  # [+errors+] Errors list where store errors messages
  # [+cmd+] Command to send
  # [+cmd_params+] Command parameters to send
  def execute_music_cmd_check_error(errors, cmd, cmd_params = {})
    result = execute_music_cmd(cmd, cmd_params)
    if result.status == :error
      errors.add( :base , 'Music server error: ' + result.info )
    end
    return errors.count == 0
  end

  # Get the form parameters
  def settings_params
    params.require(:setting).permit(
      :music_dir_path, :speech_cmd, :wikipedia_host , :initial_message ,
      :shared_folder , :image_selector , :trashcan_folder , :youtube_folder ,
      :keypad_device
    )
  end

end
