class AddFinishedToBets < ActiveRecord::Migration
  def change
    add_column :bets, :finished, :boolean
  end
end
