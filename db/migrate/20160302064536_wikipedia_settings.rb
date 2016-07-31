class WikipediaSettings < ActiveRecord::Migration
  def change

    change_table :settings do |t|
      t.string :image_selector , limit: Constants::URL_MAX_LENGTH ,
        default: Setting::DEFAULT_IMAGE_SELECTOR
    end

  end
end
