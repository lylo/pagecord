class AddExternalLinksInNewTabToBlogs < ActiveRecord::Migration[8.2]
  def change
    add_column :blogs, :external_links_in_new_tab, :boolean, default: false, null: false
  end
end
