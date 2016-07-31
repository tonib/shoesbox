class IndicesSongs < ActiveRecord::Migration
  def change
    change_table :songs do |t|
      t.index [ :artist_id , :album_id , :track , :name ]
    end
  end
end
