class CreateAccessRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :access_requests do |t|
      t.string :token_digest
      t.references :user, null: false, foreign_key: true
      t.datetime :expires_at, null: false
      t.datetime :accepted_at

      t.timestamps
    end

    add_index :access_requests, :token_digest, unique: true
    add_index :access_requests, :expires_at
  end
end
