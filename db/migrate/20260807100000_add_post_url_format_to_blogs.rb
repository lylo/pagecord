class AddPostUrlFormatToBlogs < ActiveRecord::Migration[8.2]
  def change
    add_column :blogs, :post_url_format, :string, null: false, default: "flat"
    add_column :blogs, :post_url_prefix, :string
  end
end
