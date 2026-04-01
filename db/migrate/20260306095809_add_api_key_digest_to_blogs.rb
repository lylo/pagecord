class AddApiKeyDigestToBlogs < ActiveRecord::Migration[8.2]
  def change
    add_column :blogs, :api_key_digest, :string
    add_column :blogs, :api_key_hint, :string
    add_index :blogs, :api_key_digest, unique: true
  end
end
