class AddReviewedAtToBlogs < ActiveRecord::Migration[8.2]
  def up
    add_column :blogs, :reviewed_at, :datetime
    add_index :blogs, :reviewed_at

    # Everything that predates the review queue counts as reviewed.
    execute "UPDATE blogs SET reviewed_at = NOW()"
  end

  def down
    remove_column :blogs, :reviewed_at
  end
end
