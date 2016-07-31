
require 'active_record'
require_relative 'arutils'
require 'activerecord-import'

# Tool to do bulk operations on db, grouped by transaction
class BulkOperation

  # Number or registers operated
  attr_reader :n_registers

  # Block size for operations
  attr_accessor :block_size

  # Columns to insert. It's only applied for insertions. If it's nil, it's
  # not used. If not, they are the columns to import
  attr_accessor :insert_columns

  # Constructor
  # [+operation+] Operation to do :insert / :update / :destroy
  # [+table+] Only used if operation is :insert. It's the Class of the table
  # where to insert
  # [+block_size+] Block size for operations
  # [+insert_columns+] Columns to insert. It's only applied for insertions.
  # If it's nil, it's not used. If not, they are the columns to import
  def initialize(operation, table = nil , block_size = 100, insert_columns = nil)
    @operation = operation
    @table_class = table
    @block_size = block_size
    @n_registers = 0
    @current_block = []
    @insert_columns = insert_columns
  end

  # Add a record to the current block for the operation. If the operation is
  # :insert and insert_columns property is not null, the record should be an
  # array with the column values. Otherwise it's an ActiveRecord object.
  # If the current block is big enought, the db will be modified
  # [+record+] Active record / array to add to the bulk operation
  def <<(record)
    @current_block << record
    do_bulk_block
  end

  # Check if the current block is big enought. If it is, the db will be modified
  # [+force+] True if the block should be send to the database, with any size
  def do_bulk_block(force = false)

    return if !force && @current_block.length < @block_size

    if @operation == :insert
      # activerecord-import insertions
      # Disable "DEPRECATION WARNING: `serialized_attributes` is deprecated without replacement, and will be removed in Rails 5.0. (called from do_bulk_block at /home/toni/proyectos/AptanaWorkspace/shoesbox/lib/active_record_utils/bulk_operation.rb:44)"
      ActiveSupport::Deprecation.silence do
        if @insert_columns
          # Importing arrays
          @table_class.import @insert_columns, @current_block, validate: false
        else
          # Importing active record objects
          @table_class.import @current_block, validate: false
        end
        @n_registers += @current_block.count
      end
    else
      ActiveRecord::Base.transaction do
        @current_block.each do |record|
          case @operation
          when :save
            ARUtils::save_cmdline record
          when :destroy
            ARUtils::destroy_cmdline record
          else
            raise "Unknown operation #{@operation}"
          end
          @n_registers += 1
        end
      end
    end

    @current_block.clear
  end

  # Execute a code block, doing all the operations on the db
  def do_bulk
    yield
    do_bulk_block(true)
  end

  # Execute a code block, doing all the operations on the db
  # [+operation+] Operation to do :insert / :update / :destroy
  # [+table+] Only used if operation is :insert. It's the Class of the table
  # where to insert
  # [+block_size+] Block size for operations
  # [+bulk+] The BulkOperation object to operate with the db
  # [+insert_columns+] Columns to insert. It's only applied for insertions.
  # If it's nil, it's not used. If not, they are the columns to import
  def self.bulk(operation, table = nil, block_size = 100, insert_columns = nil)
    bulk = BulkOperation.new(operation, table , block_size, insert_columns)
    yield bulk
    bulk.do_bulk_block(true)
    return bulk.n_registers
  end

end
