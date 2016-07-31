class DbCreationV2 < ActiveRecord::Migration
  def change

    # ARTISTS
    create_table :artists do |t|
      # Columns
      t.string :name , index: true , limit: Constants::NAME_MAX_LENGTH
      t.string :wikilink , limit: Constants::URL_MAX_LENGTH

      # Timestamps
      t.timestamps null: false

    end

    # ALBUMS
    create_table :albums do |t|

      # Fields
      t.string :name, limit: Constants::NAME_MAX_LENGTH, index: true
      t.string :wikilink, limit: Constants::URL_MAX_LENGTH
      t.integer :year, scale: 4

      # Timestamps
      t.timestamps null: false

    end

    # SONGS
    create_table :songs do |t|

      # Fields
      t.string :name, limit: Constants::NAME_MAX_LENGTH, index: true
      t.string :path, limit: Constants::PATH_MAX_LENGTH, index: true
      t.string :genre, limit: Constants::NAME_MAX_LENGTH, index: true
      t.integer :seconds, scale: 9
      t.integer :track , scale: 9

      # Relations
      t.references :album, index: true, foreign_key: true
      t.references :artist, index: true, foreign_key: true

      # Timestamps
      t.timestamps null: false

      # Indices
      t.index [ :album_id , :track , :name ]
    end

    # PLAY LISTS
    create_table :play_lists do |t|
      # Fields
      t.string :name, limit: Constants::NAME_MAX_LENGTH , index:true

      # Timestamps
      t.timestamps null: false
    end

    # PLAY LIST SONGS
    create_table :play_list_songs do |t|

      # Fields
      t.integer :song_order
      t.timestamps null: false

      # Relations
      t.references :play_list, index: true, foreign_key: true
      t.references :song, index: true, foreign_key: true

      # Indices
      t.index [ :play_list_id , :song_order ]

    end

    # PLAYER STATE
    create_table :player_states do |t|
      # Fields
      t.references :play_list_song, index: true, foreign_key: true
      t.datetime :play_start
      t.decimal :seconds_offset , precision: 8, scale: 2, null: false
      t.boolean :paused, null: false
      t.integer :volume , null: false

      t.timestamps null: false
    end

    # SETTINGS
    create_table :settings do |t|

      # Fields
      t.string :music_dir_path, limit: Constants::PATH_MAX_LENGTH
      t.string :speech_cmd, limit: 60
      t.string :wikipedia_host, limit: 100
      t.string :initial_message, limit: 200
      t.string :shared_folder, limit: Constants::PATH_MAX_LENGTH, null: false

      t.timestamps null: false
    end

  end
end
