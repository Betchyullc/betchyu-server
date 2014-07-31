class AddAcceptedAtAndFinishedAtToBet < ActiveRecord::Migration
  def change
    add_column :bets, :accepted_at, :datetime
    add_column :bets, :finished_at, :datetime
  end
end
