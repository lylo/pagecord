class TidyPostCommentIndexes < ActiveRecord::Migration[8.2]
  disable_ddl_transaction!

  def change
    # t.references :post created this; (post_id, approved_at) already serves
    # every lookup it does, since post_id is the leftmost column.
    remove_index :post_comments, :post_id, name: "index_post_comments_on_post_id",
      algorithm: :concurrently, if_exists: true

    # The digest job sweeps pending comments by created_at across every blog.
    # Partial, so rows drop out of the index as soon as they're approved.
    add_index :post_comments, :created_at, where: "approved_at IS NULL",
      name: "index_post_comments_on_pending_created_at",
      algorithm: :concurrently, if_not_exists: true
  end
end
