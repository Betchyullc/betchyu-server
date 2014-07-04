class AddToToTransaction < ActiveRecord::Migration
  def change
    add_column :transactions, :to, :string
  end
end
