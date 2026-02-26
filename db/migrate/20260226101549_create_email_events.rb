class CreateEmailEvents < ActiveRecord::Migration[8.2]
  def change
    create_table :email_events do |t|
      t.string :message_id, null: false
      t.string :provider, null: false
      t.references :post_digest_delivery, null: false, foreign_key: true
      t.string :status, default: "sent"
      t.timestamps
    end
    add_index :email_events, :message_id, unique: true
  end
end
