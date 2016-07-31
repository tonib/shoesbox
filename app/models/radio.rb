require_relative './images_module'

# Internet radio information
class Radio < ActiveRecord::Base

  # Functions to handle the radio image
  include ImagesModule

  ###################################################
  # ATTRIBUTES
  ###################################################

  ##
  # :attr_accessor: name
  # Radio name (length = Constants::NAME_MAX_LENGTH)

  ##
  # :attr_accessor: streaming_url
  # Radio streaming url (length = Constants::URL_MAX_LENGTH)

  ##
  # :attr_accessor: web_url
  # Radio web site url. It can be nil (length = Constants::URL_MAX_LENGTH)

  ###################################################
  # VALIDATIONS
  ###################################################

  validates :name, presence: true , length: { maximum: Constants::NAME_MAX_LENGTH }
  validates :streaming_url , presence: true , length: { maximum: Constants::URL_MAX_LENGTH }

  ###################################################
  # MEMBERS
  ###################################################

  # Get the next/previous Radio
  # [+current_radio+] The current Radio. It can be nil
  # [+direction+] The direction to search:
  # * +:forward+ Search forward
  # * +:backward+ Search backward
  # [+returns+] The next Radio
  # If now there are no radios, it returns nil
  def self.next_radio( current_radio, direction = :forward )

    return bound_radio(direction) if !current_radio

    txt_order = ( direction == :forward ? 'name > ?' : 'name < ?' )
    next_radio = query_next_radio(direction)
      .where( txt_order , current_radio.name )
      .take

    next_radio = bound_radio(direction) if !next_radio

    return next_radio
  end

  # Get the radio to play when trying to play a given radio
  # [+radio+] The Radio to check. It can be nil
  # [+returns+] The Radio to play. nil if there are no radios.
  def self.start_radio(radio = nil)
    if !radio || !Radio.exists?(id: radio.id)
      # Restart from the beginning
      return bound_radio
    else
      return radio
    end
  end

  # Get the radio to play when trying to play a given radio
  # [+radio_id+] The Integer of the Radio id to check
  # [+returns+] The Radio to play. nil if there is no radio.
  def self.start_radio_id(radio_id = nil)
    return start_radio( Radio.find_by_id( radio_id ) )
  end

  ###################################################################
  private
  ###################################################################

  # Returns a query to search radios a given direction
  # [+direction+] Direction for the query order +:forward+ or +:backward+
  # [+returns+] The active record query with the order set
  def self.query_next_radio(direction = :forward)
    query = Radio.all
    if direction == :forward
      query = query.order(:name)
    else
      query = query.order(name: :desc)
    end
    return query
  end

  # Get the first or last song of the list
  # [+direction+] If it's +:forward+, it will return the first song. If it's
  # +:backward+, it will return the last song
  # [+returns+] The given PlayListSong
  def self.bound_radio(direction = :forward)
    return query_next_radio(direction).take
  end

end
