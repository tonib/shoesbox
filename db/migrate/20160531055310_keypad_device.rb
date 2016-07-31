class KeypadDevice < ActiveRecord::Migration
  def change
    change_table :settings do |t|
      t.string :keypad_device, limit: Constants::URL_MAX_LENGTH, null: false,
        default: ''
    end
  end
end
