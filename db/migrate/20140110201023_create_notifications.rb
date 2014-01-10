class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.string :user
      t.integer :type
      t.string :data

      t.timestamps
    end
  end
end
