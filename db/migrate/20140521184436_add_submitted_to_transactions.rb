class AddSubmittedToTransactions < ActiveRecord::Migration
  def change
    add_column :transactions, :submitted, :boolean
  end
end
