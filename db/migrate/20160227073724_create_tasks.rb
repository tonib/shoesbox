class CreateTasks < ActiveRecord::Migration
  def change

    # Remove timestamps from playlist songs
    change_table :play_list_songs do |t|
      t.remove :created_at
      t.remove :updated_at
    end

    # Create tasks table
    create_table :tasks do |t|
      # Fields
      t.string :name, limit: Constants::NAME_MAX_LENGTH, null: false
      t.string :status, limit: Constants::NAME_MAX_LENGTH, null: true

      t.timestamps null: false

      t.index [ :created_at ]
    end

  end
end
