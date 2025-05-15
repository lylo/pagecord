class CreateEmailChangeRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :email_change_requests do |t|
      t.string :token_digest
      t.references :user, null: false, foreign_key: true
      t.string :new_email, null: false
      t.datetime :expires_at, null: false
      t.datetime :accepted_at

      t.timestamps
    end

    add_index :email_change_requests, :token_digest, unique: true
    add_index :email_change_requests, :expires_at
  end
end
