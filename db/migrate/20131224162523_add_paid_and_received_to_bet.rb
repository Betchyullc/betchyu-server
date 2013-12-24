class AddPaidAndReceivedToBet < ActiveRecord::Migration
  def change
    add_column :bets, :paid, :boolean
    add_column :bets, :received, :boolean
  end
end
