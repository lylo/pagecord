class CreateCloudflareCustomHostnames < ActiveRecord::Migration[8.2]
  def change
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
