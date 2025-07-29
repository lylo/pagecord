class CreateSenderEmailAddresses < ActiveRecord::Migration[8.1]
  def change
    create_table :sender_email_addresses do |t|
      t.references :blog, null: false, foreign_key: true
      t.string :email, null: false
      t.string :token_digest
      t.datetime :accepted_at
      t.datetime :expires_at
      t.timestamps
    end
    add_index :sender_email_addresses, [ :blog_id, :email ], unique: true
    add_index :sender_email_addresses, :token_digest, unique: true
    add_index :sender_email_addresses, :expires_at
  end
end
