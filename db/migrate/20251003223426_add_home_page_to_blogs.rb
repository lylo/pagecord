class AddHomePageToBlogs < ActiveRecord::Migration[8.1]
  def change
    add_column :blogs, :home_page_id, :integer
    add_foreign_key :blogs, :posts, column: :home_page_id
  end
end
