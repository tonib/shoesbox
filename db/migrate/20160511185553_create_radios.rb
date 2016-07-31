class CreateRadios < ActiveRecord::Migration
  def change
    create_table :radios do |t|

      t.string :name, limit: Constants::NAME_MAX_LENGTH, index: true
      t.string :streaming_url, limit: Constants::URL_MAX_LENGTH

      t.timestamps null: false
    end
  end
end
