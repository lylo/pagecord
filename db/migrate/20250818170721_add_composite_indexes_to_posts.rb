class AddCompositeIndexesToPosts < ActiveRecord::Migration[8.1]
  def change
    # Composite index for published posts lookup - most common query pattern
    add_index :posts, [ :blog_id, :status, :published_at ],
              order: { published_at: :desc },
              where: "status = 1",
              name: "index_posts_published_lookup"

    # Composite index for search filtering across both published and draft posts
    add_index :posts, [ :blog_id, :status ],
              where: "status IN (0, 1)",
              name: "index_posts_search_filter"
  end
end
