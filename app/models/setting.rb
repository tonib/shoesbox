require 'mkmf'

# Stores the application settings
class Setting < ActiveRecord::Base

  # Default music directory
  DEFAULT_MUSIC_DIR_PATH = '/home/toni/Música/grabados'

  # Default speech command line program
  DEFAULT_SPEECH_CMD = 'espeak -ves+f1 $TEXT'

  # Default wikipedia to use
  DEFAULT_WIKIPEDIA = 'en.wikipedia.org'

  # Default initial message
  DEFAULT_INITIAL_MESSAGE = 'Uep! Com anàm!'

  # Default shared folder
  DEFAULT_SHARED_FOLDER = '\\shoesbox\pi compartida\musica'

  # Default selector for spanish wikipedia
  DEFAULT_IMAGE_SELECTOR = 'div#content div#bodyContent table.infobox tr td a.image'

  ###################################################
  # ATTRIBUTES
  ###################################################

  ##
  # :attr_accessor: music_dir_path
  # Absolute path to the directory where the music is stored
  # (length = Constants::NAME_MAX_LENGTH)

  ##
  # :attr_accessor: shared_folder
  # Shared folder UNC path for the music directory path
  # (length = Constants::PATH_MAX_LENGTH)

  ##
  # :attr_accessor: speech_cmd
  # Command line to speech a text on the speakers. If it's empty, the speech
  # will be disabled. It must to contain a text '$TEXT' that will be replaced
  # by the text to speech
  # (length = 60)

  ##
  # :attr_accessor: wikipedia_host
  # Wikipedia host to link music info
  # (length = 100)

  ##
  # :attr_accessor: initial_message
  # Initial speech message to speech when the music server is started
  # (length = 200)

  ##
  # :attr_accessor: image_selector
  # CSS tag selector for artist image on wikipedia pages
  # (length = Contants::URL_MAX_LENGTH)

  ##
  # :attr_accessor: trashcan_folder
  # Folder where to store deleted songs
  # (length = Contants::PATH_MAX_LENGTH)

  ##
  # :attr_accessor: youtube_folder
  # Folder where to store downloaded songs
  # (length = Contants::PATH_MAX_LENGTH)

  ##
  # :attr_accessor: keypad_device
  # Keypad device. If it's empty, there is no keypad
  # (length = Contants::PATH_MAX_LENGTH)
  
  ###################################################
  # VALIDATIONS
  ###################################################

  validates :music_dir_path,
    presence: true ,
    length: { maximum: Constants::PATH_MAX_LENGTH }

  validates :speech_cmd ,
    length: { maximum: 60 }

  validates :wikipedia_host ,
    length: { maximum: 100 }

  validates :initial_message ,
    length: { maximum: 200 }

  validates :trashcan_folder,
    length: { maximum: Constants::PATH_MAX_LENGTH }

  validates :youtube_folder,
    length: { maximum: Constants::PATH_MAX_LENGTH }

  validate  :validate_music_dir_path ,
            :validate_speech_cmd

  ###################################################
  # MEMBERS
  ###################################################

  # Get the application settings.
  # If it does not exists, it will be created with default values
  # [+returns+] The Setting object with the application settings
  def self.get_settings
    settings = Setting.take
    if !settings
      # Create default settings
      settings = Setting.new
      settings.music_dir_path = DEFAULT_MUSIC_DIR_PATH
      settings.speech_cmd = DEFAULT_SPEECH_CMD
      settings.wikipedia_host = DEFAULT_WIKIPEDIA
      settings.shared_folder = DEFAULT_SHARED_FOLDER
      settings.initial_message = DEFAULT_INITIAL_MESSAGE
      settings.image_selector = DEFAULT_IMAGE_SELECTOR

      # Do not validate: Default values may be wrong for this computer
      settings.save(validate: false)
    end
    return settings
  end

  # Validates the music_dir_path property
  def validate_music_dir_path
    if !Dir.exists? self.music_dir_path
      errors.add( :music_dir_path , "#{self.music_dir_path} does not exist")
    end
  end

  # Validates the speech_cmd property
  def validate_speech_cmd

    # Empty value is OK
    if self.speech_cmd
      self.speech_cmd = self.speech_cmd.strip
    else
      return
    end
    return if self.speech_cmd.empty?

    array = prepare_speech_cmd(nil)

    if !find_executable array[0]
      errors.add( :speech_cmd , "#{array[0]} does not exist or it's " +
        "not on the path. It's safe to left this field empty")
    end

    if !self.speech_cmd.include? '$TEXT'
      errors.add( :speech_cmd , "#{self.speech_cmd} does not contains " +
        '$TEXT. This  will be replaced by the text to speech')
    end

  end

  # Get an Array with the command line to speech some text
  # [+text+] Text to speech. If it's nill, the text $TEXT will not be replaced
  # [+returns+] Array with the command line splitted. nil if there was
  # no speech program configured
  def prepare_speech_cmd(text)
    return nil if self.speech_cmd.empty?
    array = self.speech_cmd.split(' ')
    array = array.map{ |x| x.gsub('$TEXT' , text) } if text
    return array
  end

  # Get the shared path of a relative path
  # [+path+] relative path to convert to shared folder
  # [+returns+] the path inside self.shared_folder
  def shared_path(path)
    result = self.shared_folder
    result += '\\' if !result.ends_with?('\\')
    result += path.gsub('/' , '\\')
    return result
  end

  # Get the relative path of a file to the music directory
  # [+file_path+] The absolute file path
  # [+returns+] The relative path
  def relative_path_from_absolute(file_path)
    base_path = Pathname.new(self.music_dir_path)
    file_path = Pathname.new(file_path)
    return file_path.relative_path_from( base_path ).to_s
  end

  # Get the trashcan folder path with a trailing separator ('/')
  def trashcan_folder_normalized
    folder = self.trashcan_folder
    folder += '/' if !folder.end_with?('/')
    return folder
  end

end
