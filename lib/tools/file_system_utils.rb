
# Changes the owner and group of a file / directory to "pi"
# [+path+] file path to change
def change_owner(path)
  begin
    username = "pi"
    # Change ownership to "pi"
    puts "Changing owner of #{path} to #{username}"
    FileUtils.chown username, username, path
  rescue
    puts $!.message
    puts $!.backtrace
  end
end
