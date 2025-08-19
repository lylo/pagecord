class AddPostsCountOptimizationIndex < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!
  
  def up
    # Partial index optimized specifically for published posts count queries
    # This eliminates sequential scans when counting published posts per blog
    add_index :posts,
              :blog_id,
              where: "is_page = false AND status = 1",
              name: "index_posts_on_blog_id_published_count_only",
              algorithm: :concurrently
  end

  def down
    remove_index :posts,
                 name: "index_posts_on_blog_id_published_count_only",
                 if_exists: true
  end
end