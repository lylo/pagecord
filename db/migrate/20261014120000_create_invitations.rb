class CreateInvitations < ActiveRecord::Migration[8.2]
  def change
    create_table :invitations do |t|
      t.references :inviter, null: false, foreign_key: { to_table: :users }
      t.references :invitee, foreign_key: { to_table: :users }, index: { unique: true }
      t.string :code, null: false, index: { unique: true }
      t.datetime :redeemed_at
      t.integer :lock_version, null: false, default: 0

      t.timestamps
    end
  end
end
