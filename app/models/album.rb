
# An album with songs (active record model)
class Album < ActiveRecord::Base

  ## Name for the unknown album
  UNKNOWN_ALBUM_NAME = "Unknown album"

  ###################################################
  # ATTRIBUTES
  ###################################################

  ##
  # :attr_accessor: name
  # Album name (length = Constants::NAME_MAX_LENGTH)

  ##
  # :attr_accessor: year
  # Album year. N(4)

  ###################################################
  # RELATIONS
  ###################################################

  ##
  # :attr_accessor: artist
  # Artist owner of the song
  #belongs_to :artist

  ##
  # :attr_accessor: songs
  # Relation of the album Songs
  has_many :songs

  ###################################################
  # VALIDATIONS
  ###################################################

  validates :name, presence: true , length: { maximum: Constants::NAME_MAX_LENGTH }

  ###################################################
  # MEMBERS
  ###################################################

  ##
  # Returns an String description of the album
  def to_s
    txt = name
    txt += " (#{self.year})" if self.year && self.year > 0
    return txt
  end

  # Updates the artist and album data  on the associated mp3 files to this album
  # [+settings+] The application Setting
  def update_mp3_files(settings)
    songs.each do |song|
      song.update_file(settings)
    end
  end

  # Normalize an Album name
  # [+album_name+] The album name
  # [+returns+] The normalized album name
  def self.normalize_name(album_name)
    album_name = UNKNOWN_ALBUM_NAME if !album_name
    album_name.strip!
    album_name = UNKNOWN_ALBUM_NAME if album_name.empty?
    return album_name
  end

end
