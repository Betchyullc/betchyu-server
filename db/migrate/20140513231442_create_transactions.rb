class CreateTransactions < ActiveRecord::Migration
  def change
    create_table :transactions do |t|
      t.string :braintree_id
      t.references :bet, index: true
      t.string :user

      t.timestamps
    end
  end
end
