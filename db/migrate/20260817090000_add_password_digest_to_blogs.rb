class AddPasswordDigestToBlogs < ActiveRecord::Migration[8.2]
  def change
    add_column :blogs, :password_digest, :string
  end
end
