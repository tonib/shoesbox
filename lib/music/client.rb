require 'drb/drb'

# Client to access the music server (Server)
class Client

  # The URI to connect to the Server
  attr_accessor :server_uri

  # Constructor
  def initialize
    @server_uri = "druby://localhost:8787"
  end

  # Connects to the Server
  def connect
    # Get the server reference
    @server = DRbObject.new_with_uri(@server_uri)
  end

  # Send a command to the Server
  # [+cmd+] Name of the method of the Player to execute
  # [+returns+] The CmdResult returned from the server
  def send_command(cmd, params = {})
    # Send the command
    return @server.command cmd , params
  end

end
