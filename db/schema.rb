# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160531055310) do

  create_table "albums", force: :cascade do |t|
    t.string   "name",       limit: 120
    t.string   "wikilink",   limit: 120
    t.integer  "year",       limit: 4
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "albums", ["name"], name: "index_albums_on_name", using: :btree

  create_table "artists", force: :cascade do |t|
    t.string   "name",       limit: 120
    t.string   "wikilink",   limit: 120
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "artists", ["name"], name: "index_artists_on_name", using: :btree

  create_table "logs", force: :cascade do |t|
    t.string   "title",      limit: 256,  null: false
    t.integer  "level",      limit: 4,    null: false
    t.string   "details",    limit: 2048
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  create_table "play_list_songs", force: :cascade do |t|
    t.integer "song_order",   limit: 4
    t.integer "play_list_id", limit: 4
    t.integer "song_id",      limit: 4
  end

  add_index "play_list_songs", ["play_list_id", "song_order"], name: "index_play_list_songs_on_play_list_id_and_song_order", using: :btree
  add_index "play_list_songs", ["play_list_id"], name: "index_play_list_songs_on_play_list_id", using: :btree
  add_index "play_list_songs", ["song_id"], name: "index_play_list_songs_on_song_id", using: :btree

  create_table "play_lists", force: :cascade do |t|
    t.string   "name",       limit: 120
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "play_lists", ["name"], name: "index_play_lists_on_name", using: :btree

  create_table "player_states", force: :cascade do |t|
    t.integer  "play_list_song_id", limit: 4
    t.datetime "play_start"
    t.decimal  "seconds_offset",              precision: 8, scale: 2,             null: false
    t.boolean  "paused",                                                          null: false
    t.integer  "volume",            limit: 4,                                     null: false
    t.datetime "created_at",                                                      null: false
    t.datetime "updated_at",                                                      null: false
    t.integer  "mode",              limit: 4,                         default: 0
    t.integer  "radio_id",          limit: 4
  end

  add_index "player_states", ["play_list_song_id"], name: "index_player_states_on_play_list_song_id", using: :btree
  add_index "player_states", ["radio_id"], name: "index_player_states_on_radio_id", using: :btree

  create_table "radios", force: :cascade do |t|
    t.string   "name",          limit: 120
    t.string   "streaming_url", limit: 120
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.string   "web_url",       limit: 120
  end

  add_index "radios", ["name"], name: "index_radios_on_name", using: :btree

  create_table "settings", force: :cascade do |t|
    t.string   "music_dir_path",  limit: 400
    t.string   "speech_cmd",      limit: 60
    t.string   "wikipedia_host",  limit: 100
    t.string   "initial_message", limit: 200
    t.string   "shared_folder",   limit: 400,                                                                     null: false
    t.datetime "created_at",                                                                                      null: false
    t.datetime "updated_at",                                                                                      null: false
    t.string   "image_selector",  limit: 120, default: "div#content div#bodyContent table.infobox tr td a.image"
    t.string   "trashcan_folder", limit: 400
    t.string   "youtube_folder",  limit: 400
    t.string   "keypad_device",   limit: 120, default: "",                                                        null: false
  end

  create_table "songs", force: :cascade do |t|
    t.string   "name",        limit: 120
    t.string   "path",        limit: 400
    t.string   "genre",       limit: 120
    t.integer  "seconds",     limit: 4
    t.integer  "track",       limit: 4
    t.integer  "album_id",    limit: 4
    t.integer  "artist_id",   limit: 4
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.integer  "bitrate",     limit: 4
    t.integer  "channels",    limit: 4
    t.integer  "sample_rate", limit: 4
    t.integer  "file_size",   limit: 4
  end

  add_index "songs", ["album_id", "track", "name", "path"], name: "index_songs_on_album_id_and_track_and_name_and_path", length: {"album_id"=>nil, "track"=>nil, "name"=>nil, "path"=>255}, using: :btree
  add_index "songs", ["album_id"], name: "index_songs_on_album_id", using: :btree
  add_index "songs", ["artist_id", "album_id", "track", "name"], name: "index_songs_on_artist_id_and_album_id_and_track_and_name", using: :btree
  add_index "songs", ["artist_id"], name: "index_songs_on_artist_id", using: :btree
  add_index "songs", ["genre"], name: "index_songs_on_genre", using: :btree
  add_index "songs", ["name"], name: "index_songs_on_name", using: :btree
  add_index "songs", ["path"], name: "index_songs_on_path", length: {"path"=>255}, using: :btree

  create_table "tasks", force: :cascade do |t|
    t.string   "name",       limit: 120, null: false
    t.string   "status",     limit: 120
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "tasks", ["created_at"], name: "index_tasks_on_created_at", using: :btree

  add_foreign_key "play_list_songs", "play_lists"
  add_foreign_key "play_list_songs", "songs"
  add_foreign_key "player_states", "play_list_songs"
  add_foreign_key "player_states", "radios"
  add_foreign_key "songs", "albums"
  add_foreign_key "songs", "artists"
end
