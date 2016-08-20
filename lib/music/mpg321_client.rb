require 'open3'
require_relative '../../app/models/task'

# A client for mpg321 remote mode / play URL mode. Some of these methods
# only work with the remote mode (pause, gain, etc)
class Mpg321Client

  # Player status: Stopped
  STATUS_STOPPED = 0
  # Player status: Playing a song
  STATUS_PLAYING = 1
  # Player status: Playing a song (paused)
  STATUS_PAUSED = 2

  # Boolean. Status of the player. It's a STATUS_* value
  attr_reader :status

  # Float. Current second of the playing song
  attr_reader :current_second

  def initialize

    # Initial volume
    @level = 100

    start_process
    @n_frames = 0
    @current_second = 0.0
    @status = STATUS_STOPPED

    # PID for playing radio URL
    @url_pid = nil

    restart_reader_thread(false)
  end

  # Play a MP3 file
  # [+song_path+] The absolute song file path
  # [+wait_to_song_end+] If it's true, the execution of this method will
  # not exit until the song has finished to play
  def play( song_path , wait_to_song_end = false )

    stop_play_url

    # If the player has exited by some error, restart it
    if ! process_running?
      Log.log_warning( "mpg321 exited. Restarting..." )
      start_process
    end

    if !File.exist? song_path
      Log.log_warning( "#{song_path} does not exists. Skipped." )
      return
    end

    stop

    restart_reader_thread(wait_to_song_end)

    # Set the volume
    gain( @level )

    write_to_process "LOAD #{song_path}"
    @status = STATUS_PLAYING

    if wait_to_song_end
      @current_worker_thread.join
    end

  end

  # Play MP3 from an URL
  # [+url+] URL to play
  def play_url( url )
    # Be sure we are not running a mpg321 with remote mode
    kill_process
    begin
      # Crap to handle the semicolon on shoutcast URLs (ruby bug with spawn?)
      #cmd_line = "mpg321 --gain #{@level.to_s} #{url}"
      #cmd_line = "mpg321 --gain #{@level.to_s} \'#{url}\'"
      #cmd_line = "mpg321 --gain #{@level.to_s} #{url.gsub(';' , '\;')}"

      # None of the previos works. So, fuck off, this still works:
      cmd_line = "mpg321 --gain #{@level.to_s} #{url.gsub(';' , '')}"

      puts "Running #{cmd_line}"
      @url_pid = spawn( cmd_line )
      puts "pid #{@url_pid}"
      Process.wait @url_pid
    rescue
    end
    @url_pid = nil
  end

  def jump_to_frame(n_frame)
    write_to_process "JUMP #{n_frame.to_s}"
  end

  def jump_to_position(percentage)
    percentage = 0.0 if percentage < 0.0
    percentage = 100.0 if percentage > 100.0

    n_frame = ( percentage / 100.0 ) * @n_frames
    n_frame = n_frame.to_i
    n_frame = 0 if n_frame < 0
    n_frame = @n_frames if n_frame > @n_frames
    jump_to_frame(n_frame)
  end

  def pause
    return false if @status == STATUS_STOPPED

    @status = ( @status == STATUS_PLAYING ? STATUS_PAUSED : STATUS_PLAYING )
    write_to_process "PAUSE"
    return true
  end

  def stop

    if stop_play_url
      return
    end

    write_to_process "STOP"
    @status = STATUS_STOPPED
    @n_frames = 0
    @current_second = 0.0
    restart_reader_thread(false)
  end

  def gain(level)

    level = 0 if level < 0
    level = 100 if level > 100
    @level = level

    write_to_process "GAIN #{level.to_s}"
    return level
  end

  def increase_gain(level_increase)
    return gain( @level + level_increase )
  end

  def quit
    write_to_process "QUIT"
    @stdin.close
    @stdout.close
  end

  # Kill the currently running mpg321 process
  def kill_process

    if @wait_thr

      # Kill the worker thread
      begin
        @current_worker_thread.kill if @current_worker_thread
      rescue
        Log.log_last_exception
      end
      @current_worker_thread = nil

      begin
        puts "Killing files player PID #{@wait_thr.pid()}"
        pid = @wait_thr.pid()
        #Process.kill( 9 , pid ) # SIGKILL (the hardcore way)
        Process.kill( 15 , pid ) # SIGTERM (please quit, the polite way)
        puts "Waiting for PID #{pid}"
        Process.waitpid( pid )  # Avoid zombies
      rescue
        Log.log_last_exception
      end
      @wait_thr = nil
    end

    stop_play_url

  end

  ###############################################################
  protected
  ###############################################################

  def stop_play_url
    killed = false
    if @url_pid
      begin
        puts "Killing url player PID #{@url_pid}"
        Process.kill( 9 , @url_pid )
        puts "Waiting for PID #{@url_pid}"
        Process.waitpid( @url_pid )
        killed = true
      rescue
        Log.log_last_exception
      end
      @url_pid = nil
    end
    return killed
  end

  def write_to_process(text)
    begin
      if !process_running?
        Log.log_warning( "Process is not running... Restarting" )
        start_process
      end
      Log.log_debug( text )
  	  @stdin.puts( text + "\n" )
  	  @stdin.flush
    rescue
      Log.log_last_exception
      raise $!
    end
  end

  # Returns true if the player process is running
  def process_running?
    begin
      return false if !@wait_thr
      Process.getpgid( @wait_thr.pid() )
      return true
    rescue Errno::ESRCH
      return false
    end
  end

  def start_process
    Log.log_debug( "starting mpg321 process with remote control" )
    @stdin, @stdout, @wait_thr = Open3.popen2e('mpg321 -R remote')
    puts "mpg321 process with remote control pid: #{@wait_thr.pid()}"
  end

  def restart_reader_thread(exit_on_song_end)
    if @current_worker_thread
      @current_worker_thread.kill
    end
    @current_worker_thread = Thread.new { worker_thread(exit_on_song_end) }
  end

  def worker_thread(exit_on_song_end)
    begin

      while true
        status_line = @stdout.gets

        if !status_line
          # Process closed. Restart it
          Log.log_warning("Pipe closed")
          start_process
          # Emulate an end of song
          status_line = "@P 3\n"
        end

        if status_line == "@P 3\n"
          # Song play finished
          @status = STATUS_STOPPED
          @current_second = 0.0
          @n_frames = 0
          if exit_on_song_end
            return
          end
        end

        if status_line.start_with? "@F"
          # Frame info: @F <current-frame> <frames-remaining> <current-time> <time-remaining>
          parts = status_line.split
          @n_frames = parts[1].to_i + parts[2].to_i
          @current_second = parts[3].to_f
        end

        if status_line.start_with? "@E"
          # Error message
          Log.log_error( "mpg321 error: " + status_line )
        end
      end

    rescue
      Log.log_last_exception
      raise $!
    end
  end
end
