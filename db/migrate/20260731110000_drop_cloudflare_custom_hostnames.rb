class DropCloudflareCustomHostnames < ActiveRecord::Migration[8.2]
  # Left behind in production by the unmerged cloudflare-for-saas branch. No
  # model, no references anywhere in the tree, and zero rows.
  def up
    drop_table :cloudflare_custom_hostnames, if_exists: true
  end

  def down
    create_table :cloudflare_custom_hostnames do |t|
      t.references :blog, null: false, foreign_key: true
      t.string :domain, null: false
      t.string :external_id, null: false

      t.timestamps
    end

    add_index :cloudflare_custom_hostnames, :domain, unique: true
    add_index :cloudflare_custom_hostnames, :external_id, unique: true
    add_index :cloudflare_custom_hostnames, [ :blog_id, :domain ], unique: true
  end
end
