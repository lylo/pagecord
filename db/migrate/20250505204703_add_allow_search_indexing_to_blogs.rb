class AddAllowSearchIndexingToBlogs < ActiveRecord::Migration[8.1]
  def change
    add_column :blogs, :allow_search_indexing, :boolean, default: true, null: false
  end
end
