class AddIndexOnPublishedAtToPost < ActiveRecord::Migration[8.1]
  def change
    add_index :posts, :published_at
  end
end
