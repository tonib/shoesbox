class RadioMetadata < ActiveRecord::Migration
  def change
    change_table :radios do |t|
      t.string :web_url, limit: Constants::URL_MAX_LENGTH
    end
  end
end
