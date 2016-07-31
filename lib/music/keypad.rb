require "revdev"
require_relative '../../app/models/log'

# A keyboard events handler, Linux specific
# source: https://github.com/kui/revdev
class Keypad

  # Linux input handling ( https://github.com/kui/revdev / gem 'revdev' )
  include Revdev

  # Constructor
  # [+player+] The Player to control with the keyboard
  def initialize(player)

    begin
      @player = player

      # When the stop key is pressed 4 seconds, the device is shutdown
      # This var stores the thread that waits that time
      @shutdown_timer_thread = nil

      # Are we shutting down the device?
      @shutting_down = false

      # Grab the keyboard
      settings = Setting.get_settings
      if settings.keypad_device && !settings.keypad_device.empty?
        @evdev = EventDevice.new(settings.keypad_device)
        # This line throws an exception Invalid argument @ rb_ioctl
        # on ruby 2.2.2
        # (see https://github.com/kui/revdev/issues/3)
        #puts "*** Device Name: #{@evdev.device_name}"

        # Start the thread to read keyboard events
        @current_worker_thread = Thread.new { worker_thread }
      end
    rescue
      Log.log_last_exception
    end

  end

  ###############################################################
  protected
  ###############################################################

  def worker_thread
    begin
      loop do
        ie = @evdev.read_input_event
        # t = ie.hr_type ? "#{ie.hr_type.to_s}(#{ie.type})" : ie.type
        # c = ie.hr_code ? "#{ie.hr_code.to_s}(#{ie.code})" : ie.code
        # v = ie.hr_value ? "#{ie.hr_value.to_s}(#{ie.value})" : ie.value
        # puts "type:#{t}	code:#{c}	value:#{v}"

        #puts "#{ie.inspect}"
        if ie.hr_type == :EV_KEY && ie.hr_code == :KEY_KP0
          # Stop key event (special to handle shutdown event)

          if ie.value == 1
            # Stop key pressed. Launch the shutdown thread
            #puts "*** Stop key pressed"
            @shutdown_timer_thread = Thread.new { shutdown_thread }
          elsif ie.value == 0
            # Stop key up
            # Cancel the shutdown
            #puts "*** Stop key up"
            @shutdown_timer_thread.kill if @shutdown_timer_thread
            @shutdown_timer_thread = nil
            if !@shutting_down
              # Stop the player
              @player.stop
            end
          end

        elsif ie.hr_type == :EV_KEY && ie.value == 1
          # Key pressed
          #puts "***#{ie.hr_code}"
          case ie.hr_code
          when :KEY_KP3
            @player.next

          when :KEY_KP2
            @player.previous

          when :KEY_KPDOT
            @player.pause

          when :KEY_ENTER
            @player.start

          when :KEY_KP7
            @player.change_mode

          when :KEY_KPPLUS
            @player.change_volume({ volume_increase: 10 })

          when :KEY_KPMINUS
            @player.change_volume({ volume_increase: -10 })

          when :KEY_KPASTERISK
            @player.speech({ message: '*CURRENTPLAY*' })
          end
        end
      end
    rescue
      Log.log_last_exception
    end
  end

  ############################################################
  protected
  ############################################################

  # Worker thread called when the stop key is pressed. It should shutdown
  # the device
  def shutdown_thread
    begin
      sleep 4
      puts "Shutting down the device"
      result_text = `shutdown -h now 2>&1`
      puts result_text
      @shutting_down = $?.success?
      if !@shutting_down
        Log.log_error('Error shuting down the device', result_text)
      else
        @player.speech( { message: 'Adeu'} )
      end
    rescue
      Log.log_last_exception
    end
  end

end
