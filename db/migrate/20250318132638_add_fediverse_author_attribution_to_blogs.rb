class AddFediverseAuthorAttributionToBlogs < ActiveRecord::Migration[8.1]
  def change
    add_column :blogs, :fediverse_author_attribution, :string
  end
end
