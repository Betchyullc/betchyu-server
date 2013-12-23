class AddCurentToBet < ActiveRecord::Migration
  def change
    add_column :bets, :current, :integer
  end
end
