class AddEmailAndNameAndIsMaleAndLocationToUser < ActiveRecord::Migration
  def change
    add_column :users, :email, :string
    add_column :users, :name, :string
    add_column :users, :is_male, :boolean
    add_column :users, :location, :string
  end
end
