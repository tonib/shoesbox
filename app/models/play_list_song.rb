
# Songs on a play list (active record model)
class PlayListSong < ActiveRecord::Base

  ###################################################
  # ATTRIBUTES
  ###################################################

  ##
  # :attr_accessor: song_order
  # Song order inside the playlist. integer

  ###################################################
  # RELATIONS
  ###################################################

  ##
  # :attr_accessor: play_list
  # The PlayList owner
  belongs_to :play_list

  ##
  # :attr_accessor: song
  # The Song in the play list
  belongs_to :song

  ###################################################
  # MEMBERS
  ###################################################

  # Returns the name of the play list and the name of the song
  def to_s
    self.play_list.to_s + " " + self.song.to_s
  end
end
