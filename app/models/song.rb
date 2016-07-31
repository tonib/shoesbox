# taglib-ruby gem (gem install taglib-ruby)
require 'taglib'

# Song information (active record model)
class Song < ActiveRecord::Base

  ###################################################
  # ATTRIBUTES
  ###################################################

  ##
  # :attr_accessor: name
  # Song name (length = Constants::NAME_MAX_LENGTH)

  ##
  # :attr_accessor: path
  # Song path (length = Constants::PATH_MAX_LENGTH).
  # The path is relative to the root path of the music directory

  ##
  # :attr_accessor: genre
  # Description of the song genre (length = Constants::NAME_MAX_LENGTH).

  ##
  # :attr_accessor: seconds
  # Lenght of the song, in seconds. N(9)

  ##
  # :attr_accessor: track
  # Number of order of the song inside the owner Album. N(9)

  ##
  # :attr_accessor: bitrate
  # bit rate in kb/s (kilobit per second). N(5)

  ##
  # :attr_accessor: channels
  # Number of channels. N(1)

  ##
  # :attr_accessor: sample_rate
  # sample rate in Hz. N(6)

  ##
  # :attr_accessor: file_size
  # file size, in bytes. N(12)

  ###################################################
  # RELATIONS
  ###################################################

  ##
  # :attr_accessor: album
  # Owner Album
  belongs_to :album

  ##
  # :attr_accessor: artist
  # Owner Artist
  belongs_to :artist

  ##
  # :attr_accessor: play_list_songs
  # Relation of PlayListSong that reference to this song
  has_many :play_list_songs , dependent: :delete_all

  ###################################################
  # VALIDATIONS
  ###################################################

  validates :name, presence: true , length: { maximum: Constants::NAME_MAX_LENGTH }

  ###################################################
  # MEMBERS
  ###################################################

  # Returns the directory name of the song, relative to the music directory
  def dirname
    return File.dirname( self.path )
  end

  # Fill the song info from a audio file tags
  # [+path+] Song path, relative to the root music directory
  # [+file_tags+] File tags, type TagLib::File (http://www.rubydoc.info/gems/taglib-ruby/TagLib)
  # [+file_size+] The file size, in bytes
  def fill( path , file , file_size )

    self.path = path

    # Get file tags
    file_tags = file.tag
    if file_tags
      self.name = file_tags.title
      self.genre = file_tags.genre
      self.track = file_tags.track
    end

    # Be sure we have a name
    if !self.name || self.name.empty?
      self.name = File.basename(path, ".*")
      self.name.gsub!('_',' ')
    end
    self.name.strip!

    # Try to extract the track number
    begin
      if self.track == 0 && self.name =~ /\A\d+.*/
        # Get the initial number:
        self.track = self.name[/\A\d+/].to_i
        self.track = 0 if self.track < 0 || self.track > 9999
      end
    rescue
    end

    # Cut long names
    if self.name.length > Constants::NAME_MAX_LENGTH
      self.name = self.name[0..(Constants::NAME_MAX_LENGTH-1)]
    end
    if self.genre && self.genre.length > Constants::NAME_MAX_LENGTH
      self.genre = self.genre[0..(Constants::NAME_MAX_LENGTH-1)]
    end
    
    # Get audio properties
    audio_props = file.audio_properties
    if audio_props
      self.seconds = audio_props.length
      self.bitrate = audio_props.bitrate
      self.channels = audio_props.channels
      self.sample_rate = audio_props.sample_rate
    end

    # File size
    self.file_size = file_size

  end

  # Returns the song description
  def to_s(show_id = false)
    s = ''
    s += self.track.to_s + ". " if self.track && self.track > 0
    s += self.name ? self.name : "Unknown song name"
    s += " / " + self.album.to_s
    s += " / " + self.artist.to_s
    s += " (#{self.id})" if show_id
    return s
  end

  # Returns a String with the song length formatted
  def seconds_to_s
    return Song.format_seconds_to_s(self.seconds)
  end

  # Returns the absolute path of the song file
  # [+settings+] The Setting with the base music directory
  def full_path(settings)
    return File.join( settings.music_dir_path , self.path )
  end

  # Update the meta tags on the mp3 file
  # [+settings+] The application Setting
  def update_file(settings)
    file_path = self.full_path(settings)
    TagLib::MPEG::File.open(file_path) do |file|
      file.tag.artist = self.artist.name
      file.tag.album =  self.album.name
      file.tag.year = self.album.year ? self.album.year : 0
      file.tag.genre = self.genre
      file.tag.title = self.name
      file.save
    end
  end

  # Returns a String with a number of seconds formatted
  # [+seconds+] Integer with the number of seconds
  # [+returns+] String with the seconds formated as mm:ss
  def self.format_seconds_to_s(seconds)
    minutes = seconds / 60
    seconds_rest = seconds % 60
    return "#{minutes}:#{sprintf '%02d', seconds_rest}"
  end

end
