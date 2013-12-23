class CreateInvites < ActiveRecord::Migration
  def change
    create_table :invites do |t|
      t.string :status
      t.string :invitee
      t.string :inviter
      t.references :bet, index: true

      t.timestamps
    end
  end
end
