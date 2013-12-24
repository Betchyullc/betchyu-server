class CreateUpdates < ActiveRecord::Migration
  def change
    create_table :updates do |t|
      t.integer :value
      t.references :bet, index: true

      t.timestamps
    end
  end
end
