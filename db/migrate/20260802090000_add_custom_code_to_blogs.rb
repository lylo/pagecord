class AddCustomCodeToBlogs < ActiveRecord::Migration[8.2]
  def change
    add_column :blogs, :custom_head_html, :text
    add_column :blogs, :custom_body_html, :text
    add_column :blogs, :custom_code_enabled, :boolean, default: true, null: false
  end
end
