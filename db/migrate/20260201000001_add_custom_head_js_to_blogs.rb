class AddCustomHeadJsToBlogs < ActiveRecord::Migration[8.2]
  def change
    add_column :blogs, :custom_head_html, :text

    # Remove old unused analytics columns
    remove_column :blogs, :analytics_id, :string
    remove_column :blogs, :analytics_service, :string
  end
end
