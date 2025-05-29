class RenameNameToSubdomainOnBlogs < ActiveRecord::Migration[8.1]
  def change
    rename_column :blogs, :name, :subdomain
  end
end
