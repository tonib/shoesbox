
require 'active_record'

# Active record utility functions
class ARUtils

  # Try to save a record and log errors to the std output
  # [+record+] Record to save
  # [+return+] True if the save was ok. False otherwise
  def self.save_cmdline(record)
    if !record.save
      puts "Error saving #{record.to_s}:"
      log_errors record
      return false
    end
    return true
  end

  # Try to save a record and log errors to the std output
  # [+record+] Record to destroy
  # [+return+] True if the destroy was ok. False otherwise
  def self.destroy_cmdline(record)
    if !record.destroy
      puts "Error deleting #{record.to_s}:"
      log_errors record
      return false
    end
    return true
  end

  # Log errors of a record to the std output
  # [+record+] Record containing the errors to log
  def self.log_errors(record)
    record.errors.full_messages.each { |msg| puts "*** " << msg }
  end

  # Load a field from a record
  # [+model+] The model Class
  # [+id+] The record id
  # [+field+] The field to get
  # [+returns+] The field value for the record. It can be nil
  def self.field( model , id , field )
    array = model.where( id: id ).pluck( field )
    return nil if array.length == 0
    return array[0]
  end

end
