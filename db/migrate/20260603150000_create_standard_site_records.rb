class CreateStandardSiteRecords < ActiveRecord::Migration[8.2]
  def change
    create_table :standard_site_accounts do |t|
      t.references :blog, null: false, foreign_key: true, index: { unique: true }
      t.string :handle, null: false
      t.string :did, null: false
      t.string :pds_url, null: false, default: "https://bsky.social"
      t.text :access_jwt_ciphertext
      t.text :refresh_jwt_ciphertext
      t.datetime :connected_at
      t.datetime :disconnected_at
      t.timestamps
    end

    create_table :standard_site_publications do |t|
      t.references :blog, null: false, foreign_key: true, index: { unique: true }
      t.string :at_uri
      t.string :cid
      t.string :rkey, null: false, default: "self"
      t.integer :sync_status, null: false, default: 0
      t.datetime :last_synced_at
      t.text :sync_error
      t.timestamps
    end

    create_table :standard_site_documents do |t|
      t.references :post, null: false, foreign_key: true, index: { unique: true }
      t.string :at_uri
      t.string :cid
      t.string :rkey, null: false
      t.integer :sync_status, null: false, default: 0
      t.datetime :last_synced_at
      t.text :sync_error
      t.timestamps
    end
  end
end
