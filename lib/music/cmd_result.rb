
# Information about a command execution result on the music player
class CmdResult

  # Command execution status. It can be :success or :error
  attr_accessor :status

  # String with extra info about the execution. It can be null
  attr_accessor :info

  #Constructor
  # [+status+] Command execution status. By default it's :sucess
  # [+info+] String with extra info about the execution.. By default it's nil
  def initialize(status = :success , info = nil)
    @status = status
    @info = info
  end
  
end
