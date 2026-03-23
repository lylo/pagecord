class AddExcerptToPosts < ActiveRecord::Migration[8.2]
  def change
    add_column :posts, :excerpt, :text
  end
end
