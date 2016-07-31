
require_relative 'client'

client = Client.new
client.connect
client.send_command ARGV[0]
