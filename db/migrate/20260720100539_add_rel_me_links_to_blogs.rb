class AddRelMeLinksToBlogs < ActiveRecord::Migration[8.2]
  def change
    add_column :blogs, :rel_me_links, :text
  end
end
