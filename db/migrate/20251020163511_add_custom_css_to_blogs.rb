class AddCustomCssToBlogs < ActiveRecord::Migration[8.1]
  def change
    add_column :blogs, :custom_css, :text
  end
end
