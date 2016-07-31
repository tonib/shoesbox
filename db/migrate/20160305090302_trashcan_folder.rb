class TrashcanFolder < ActiveRecord::Migration
  def change

    change_table :settings do |t|
      t.string :trashcan_folder, limit: Constants::PATH_MAX_LENGTH
    end

  end
end
