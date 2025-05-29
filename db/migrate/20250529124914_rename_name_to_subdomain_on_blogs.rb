class RenameNameToSubdomainOnBlogs < ActiveRecord::Migration[8.1]
  def change
    rename_column :blogs, :name, :subdomain
    rename_index "index_blogs_on_name", "index_blogs_on_subdomain"
  end
end
