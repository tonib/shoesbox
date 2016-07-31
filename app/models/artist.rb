
require 'fileutils'
require 'i18n'
require_relative './images_module'

# Artist information (active record model)
class Artist < ActiveRecord::Base

  # Functions to handle the artist image
  include ImagesModule

  # Name for the unknown artist
  UNKNOWN_ARTIST_NAME = "Unknown artist"

  ###################################################
  # ATTRIBUTES
  ###################################################

  ##
  # :attr_accessor: name
  # Artist name (length = Constants::NAME_MAX_LENGTH)

  ##
  # :attr_accessor: wikilink
  # Wikipedia url page. nil if it has not been searched yet

  ###################################################
  # RELATIONS
  ###################################################

  ##
  # :attr_accessor: songs
  # Relation of the artist Songs
  has_many :songs

  ###################################################
  # VALIDATIONS
  ###################################################

  validates :name, presence: true , length: { maximum: Constants::NAME_MAX_LENGTH }
  validates :wikilink , length: { maximum: Constants::URL_MAX_LENGTH }
  validate :validate_name

  ###################################################
  # MEMBERS
  ###################################################

  # Returns a String with the artist name
  def to_s
    self.name
  end

  # There is a wikipedia link available?
  def wikilink_available?
    wikilink && !wikilink.empty?
  end

  # Updates the artist name on the associated mp3 files to this artist
  # [+settings+] The application Setting
  def update_mp3_files(settings)
      self.songs.each { |song| song.update_file(settings) }
  end

  # Join this artist to other. All songs from this artist will be moved
  # to the target artist, and this artist will be removed
  # [+settings+] The Setting application object
  # [+target_artist+] The Artist to join this
  def join_to_other(settings, target_artist)

    # Move each song of this artist to the new
    self.songs.each do |song|
      song.artist = target_artist
      song.save
      # Update the file
      song.update_file(settings)
    end

    # Delete the artist
    self.destroy

  end

  # Get an artist album by its name
  # [+album_name+] The album name
  # [+returns+] The given Album. nil if it was not found
  def album_by_name(album_name)
    a = self.albums.where( name: album_name ).take
    puts a.inspect
    puts a.name
    return a
  end

  # Normalize an Artist name
  # [+artist_name+] The artist name
  # [+returns+] The normalized artist name
  def self.normalize_name(artist_name)
    artist_name = UNKNOWN_ARTIST_NAME if !artist_name
    artist_name.strip!
    artist_name = UNKNOWN_ARTIST_NAME if artist_name.empty?
    return artist_name
  end

  # URL witht artist videos
  def youtube_url
    return "https://www.youtube.com/results?search_query=#{CGI.escape(self.name)}"
  end

  #######################################################
  protected
  #######################################################

  # Check name uniqueness
  def validate_name
    repeaded = Artist
      .where(name: self.name)
      .where.not(id: self.id)
      .take
    if repeaded
      errors.add(:name , 'There is another artist with the  same name. If ' +
        'both artists are the same, join them')
    end
  end

end
