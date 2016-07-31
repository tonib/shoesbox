class RadioPlayerState < ActiveRecord::Migration
  def change
    change_table :player_states do |t|
      t.integer :mode, scale: 1, default: PlayerState::SOURCE_FILE_SONGS
      t.references :radio, index: true, foreign_key: true
    end
  end
end
