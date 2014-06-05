class RewriteBets < ActiveRecord::Migration
  def change
    change_table :bets do |t|
      # the renames
      t.rename :betNoun, :noun
      t.rename :betVerb, :verb
      t.remove :betAmount
      t.decimal :amount  # two lines cause we change the type as well
      t.rename :ownStakeType, :stakeType
      t.rename :ownStakeAmount, :stakeAmount

      # the adds
      t.string :status
      t.decimal :initial
      t.integer :duration

      # the removes
      t.remove :endDate, :opponent, :opponentStakeType, :opponentStakeAmount, :current, :paid, :received, :finished
    end
  end
end
