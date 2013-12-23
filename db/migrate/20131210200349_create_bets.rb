class CreateBets < ActiveRecord::Migration
  def change
    create_table :bets do |t|
      t.integer :betAmount
      t.string :betNoun
      t.string :betVerb
      t.date :endDate
      t.string :opponent
      t.integer :opponentStakeAmount
      t.string :opponentStakeType
      t.string :owner
      t.integer :ownStakeAmount
      t.string :ownStakeType

      t.timestamps
    end
  end
end
