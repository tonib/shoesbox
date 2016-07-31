require_relative '../music/cmd_result'

# Create a tar file without directories structure
# [+file_paths+] Array of file paths to tar
# [+zip_path+] Path of the destination zip file
# [+returns+] A CmdResult with the operation result
def create_zip_file(file_paths, zip_path)

  # Delete the file if it exists
  File.delete(zip_path) if File.exist?(zip_path)

  # Do not compress and dont store file paths
  cmd = "zip -Z store -j \"#{zip_path}\" "
  file_paths.each { |file| cmd += "\"#{file}\" " }

  # Execute the command
  puts cmd
  result_text = `#{cmd} 2>&1`
  #puts result_text

  # Return the op result
  return CmdResult.new( $?.success? ? :success : :error , result_text )

end
