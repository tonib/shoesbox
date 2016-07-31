require_relative 'play_list_song'
require_relative '../../lib/active_record_utils/bulk_operation.rb'

# Header of a play list (active record model)
class PlayList < ActiveRecord::Base

  # Name for the server speakers reproduction queue
  REPRODUCTION_QUEUE_NAME = "Reproduction queue"

  ###################################################
  # ATTRIBUTES
  ###################################################

  ##
  # :attr_accessor: name
  # Play list name (length = Constants::NAME_MAX_LENGTH)
  # If name == REPRODUCTION_QUEUE_NAME, this is the reproduction queue

  ###################################################
  # RELATIONS
  ###################################################

  ##
  # :attr_accessor: play_list_songs
  # Relation of PlayListSong owned by the playlist
  has_many :play_list_songs , dependent: :delete_all

  ###################################################
  # VALIDATIONS
  ###################################################

  validates :name, presence: true , length: { maximum: Constants::NAME_MAX_LENGTH }

  ###################################################
  # MEMBERS
  ###################################################

  # Get the reproduction queue
  # [+returns+] The reproduction queue
  def self.reproduction_queue
    PlayList.find_or_create_by(name: REPRODUCTION_QUEUE_NAME)
  end

  # Queue all music for reproduction
  def self.queue_all_and_shuffle
    queue = self.reproduction_queue

    # Clean the current queue
    queue.play_list_songs.clear

    # Get all songs and random sort them
    songs_ids = Song.all.pluck( :id ).to_a.shuffle

    # Create the play list songs
    queue.add_songs_ids(songs_ids, 1)
  end

  # Add a song to the end of the play list
  # [+song+] Song to add
  # [+returns+] The PlayListSong added
  def add_song(song)

    order = play_list_songs.maximum(:song_order)
    order = 0 if !order
    order += 1

    pls = PlayListSong.new
    pls.play_list = self
    pls.song = song
    pls.song_order = order
    ARUtils.save_cmdline(pls)

    return pls
  end

  # Add songs ids to this play list
  # [+songs_ids+] Collection of Song ids to add
  def add_songs_ids(songs_ids, start_order = 0)

    # Get the first order
    if start_order > 0
      order = start_order
    else
      order = play_list_songs.maximum(:song_order)
      order = 0 if !order
      order += 1
    end

    columns = [ :play_list_id , :song_id , :song_order ]
    BulkOperation.bulk(:insert, PlayListSong, 1000, columns) do |bulk|
      songs_ids.each do |song_id|
        bulk << [ self.id , song_id , order ]
        order += 1
      end
    end
  end

  # Get the first song of the list
  # [+returns+] The first PlayListSong of #play_list_songs. nil if the list is empty
  def first_song
    return bound_song(:forward)
  end

  # Get the last song of the list
  # [+returns+] The last PlayListSong of #play_list_songs. nil if the list is empty
  def last_song
    return bound_song(:backward)
  end

  # Get the next/previous Song of the play list
  # [+current_song+] The PlayListSong of the current song. It can be nil
  # [+direction+] The direction to search the song:
  # * +:forward+ Search forward
  # * +:backward+ Search backward
  # [+returns+] The next song to +current_song+ on the play list.
  # If the list is now empty, it returns nil
  def next_song(current_song, direction = :forward)

    return bound_song(direction) if !current_song

    txt_order = direction == :forward ? 'song_order > ?' : 'song_order < ?'
    next_song = query_next_song(direction)
      .where( txt_order , current_song.song_order)
      .take

    next_song = bound_song(direction) if !next_song

    return next_song
  end

  # Returns the playlist name
  def to_s
    self.name
  end

  # Get the song to play when trying to play a given song
  # [+play_list_song+] The PlayListSong to check on the play list. It can be nil
  # [+returns+] The PlayListSong to play. nil if there is no song.
  def start_song(play_list_song = nil)
    if !play_list_song || !play_list_songs.exists?(id: play_list_song.id)
      # Restart the play list from the beginning
      return first_song
    else
      return play_list_song
    end
  end

  # Get the song to play when trying to play a given song
  # [+play_list_song+] The Integer of the PlayListSong id to check on the play list
  # [+returns+] The PlayListSong to play. nil if there is no song.
  def start_song_id(play_list_song_id = nil)
    return start_song( PlayListSong.find_by_id(play_list_song_id) )
  end

  # Return true if it's the phisical audio reproduction queue
  def is_reproduction_queue?
    self.name == REPRODUCTION_QUEUE_NAME
  end

  def find_or_add_song(song_id)
    song = Song.find_by_id(song_id)
    play_list_song = self.play_list_songs.where(song: song).take
    if !play_list_song
      # Add the song
      play_list_song = self.add_song(song)
    end
    return play_list_song
  end

  ###################################################################
  private
  ###################################################################

  # Returns a query to search songs on the play list on a given direction
  # [+direction+] Direction for the query order +:forward+ or +:backward+
  # [+returns+] The active record query with the order set
  def query_next_song(direction = :forward)
    query = self.play_list_songs.includes(:song)
    if direction == :forward
      query = query.order(:song_order)
    else
      query = query.order(song_order: :desc)
    end
    return query
  end

  # Get the first or last song of the list
  # [+direction+] If it's +:forward+, it will return the first song. If it's
  # +:backward+, it will return the last song
  # [+returns+] The given PlayListSong
  def bound_song(direction = :forward)
    return query_next_song(direction).take
  end

end
