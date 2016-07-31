
# Table with the application messages
class Log < ActiveRecord::Base

  DEBUG = 0
  INFO = 1
  WARNING = 2
  ERROR = 3

  ###################################################
  # ATTRIBUTES
  ###################################################

  ##
  # :attr_accessor: title
  # String the log entry title. V(256)

  ##
  # :attr_accessor: level
  # Log level. It can be DEBUG, INFO, WARNING or ERROR. N(1)

  ##
  # :attr_accessor: details
  # Log details. It can be null. V(2048)

  ###################################################
  # MEMBERS
  ###################################################

  # Get a detailed text description about an exception
  # [+exception+] The exception
  # [+returns+] The exception description string
  def self.exception_details(exception)
    return "Message: #{exception.message}\nClass: #{exception.class}\n#{exception.backtrace.join("\n")}"
  end

  # Store the last log ( the [$!] exception )
  # [+title+] Title to set on the log. If it's nil, the title will be the
  # exception message
  def self.log_last_exception( title = nil )
    Log.log_exception( $! )
  end

  # Store an exception
  # [+exception+] The exception to log
  # [+title+] Title to set on the log. If it's nil, the title will be the
  # exception message
  def self.log_exception( exception, title = nil )
    title = 'Exception: ' + exception.message if !title
    Log.log( title , ERROR , Log.exception_details( exception ) )
  end

  # Store a error log text
  # [+title+] Error title
  # [+details+] Error details (optional)
  def self.log_error(title, details = nil)
    Log.log(title, ERROR, details)
  end

  # Store a warning log text
  # [+title+] Warning title
  # [+details+] Warning details (optional)
  def self.log_warning(title, details = nil)
    Log.log(title, WARNING, details)
  end

  # Store a debug log text
  # [+title+] Debug title
  # [+details+] Debug details (optional)
  def self.log_debug(title, details = nil)
    Log.log(title, DEBUG, details)
  end

  # Store a log entry
  # [+title+] Entry title
  # [+level+] Entry level (DEBUG, INFO, WARNING or ERROR)
  # [+details+] Entry details (optional)
  def self.log(title, level, details = nil)

    begin
      puts "#{Log.level_to_s(level)}: #{title}"
      puts "Details:\n#{details}" if details

      if level > DEBUG
        # Cut texts:
        title = title[ 0 , 256 ] if title.length > 256
        details = details[ 0 , 2048 ] if details && details.length > 2048

        # Save the log
        l = Log.new
        l.level = level
        l.title = title
        l.details = details
        l.save
      end
    rescue
      puts "ERROR saving log:"
      puts Log.exception_details( $! )
    end

  end

  # Get a text description for this log level
  def level_to_s
    return Log.level_to_s(self.level)
  end

  # True if the log has details
  def has_details?
    return details && !details.equal?('')
  end

  # Get a text description for a log level
  # [+level+] The log level (ERROR, INFO, etc.)
  # [+returns+] The level description
  def self.level_to_s(level)
    case level
    when DEBUG
      return 'DEBUG'
    when INFO
      return 'INFO'
    when WARNING
      return 'WARNING'
    when ERROR
      return 'ERROR'
    else
      return "???"
    end
  end

end
