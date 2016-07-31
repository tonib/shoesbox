class MoreSongFields < ActiveRecord::Migration

  def change
    change_table :songs do |t|

      t.integer :bitrate, scale: 5
      t.integer :channels, scale: 1
      t.integer :sample_rate, scale: 6
      t.integer :file_size, scale: 12
    end
  end
end
