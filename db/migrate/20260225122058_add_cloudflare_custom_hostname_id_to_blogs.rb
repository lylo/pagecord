class AddCloudflareCustomHostnameIdToBlogs < ActiveRecord::Migration[8.2]
  def change
    add_column :blogs, :cloudflare_custom_hostname_id, :string
    add_index :blogs, :cloudflare_custom_hostname_id, unique: true,
      where: "cloudflare_custom_hostname_id IS NOT NULL"
  end
end
