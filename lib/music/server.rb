require 'drb/drb'
require_relative 'player'

# The URI for the server to connect to
MUSIC_SERVICE_URI="druby://localhost:8787"

# The server frontend for a Player. It can be accessed trough the Client class
class Server

  # Constructor
  def initialize
    # The music player
    @player = Player.new
    # Thread safe execution of commands:
    @semaphore = Mutex.new
  end

  # Run a command on the Player
  # [+cmd+] String with the method name of the Player to execute
  # [+params+] Hash with the parameters for the command
  # [+returns+] A CmdResult with the command result
  def command(cmd, params = {})
    # Thread safe execution of commands:
    @semaphore.synchronize do
      begin
        puts "Command #{cmd} received"
        if @player.respond_to? cmd
          # Execute the command
          if params && !params.empty?
            result = @player.send(cmd, params)
          else
            result = @player.send(cmd)
          end
          if result.instance_of? CmdResult
            return result
          else
            # Return :success
            return CmdResult.new
          end
        else
          return CmdResult.new( :error , "Wrong command #{cmd}" )
        end
      rescue
        Log.log_last_exception
        return CmdResult.new( :error , "#{$!.message}" )
      end
    end
  end

end

# The object that handles requests on the server
FRONT_OBJECT = Server.new

# Start the server
DRb.start_service(MUSIC_SERVICE_URI, FRONT_OBJECT)
puts "Server started"

# Wait for the drb server thread to finish before exiting.
DRb.thread.join
