class AddPrivateFieldsToBlogs < ActiveRecord::Migration[8.1]
  def change
    add_column :blogs, :is_private, :boolean, default: false, null: false
    add_column :blogs, :password_digest, :string
  end
end
