class CreateLogs < ActiveRecord::Migration
  def change
    create_table :logs do |t|

      t.string :title , limit: 256, null: false
      t.integer :level, scale: 1, null: false
      t.string :details , limit: 2048

      t.timestamps null: false
    end
  end
end
