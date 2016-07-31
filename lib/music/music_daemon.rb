require 'daemons'

# http://daemons.rubyforge.org/
Daemons.run( File.join(File.dirname(__FILE__), 'server.rb') )
