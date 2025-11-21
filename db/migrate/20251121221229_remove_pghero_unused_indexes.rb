class RemovePgheroUnusedIndexes < ActiveRecord::Migration[8.2]
  def change
    remove_index :action_text_rich_texts, name: "index_action_text_rich_texts_on_post_content", if_exists: true
    remove_index :blog_exports, name: "index_blog_exports_on_blog_id", if_exists: true
    remove_index :custom_domain_changes, name: "index_custom_domain_changes_on_blog_id", if_exists: true
    remove_index :navigation_items, name: "index_navigation_items_on_type", if_exists: true
    remove_index :open_graph_images, name: "index_open_graph_images_on_post_id", if_exists: true
    remove_index :post_replies, name: "index_post_replies_on_created_at", if_exists: true
    remove_index :post_replies, name: "index_post_replies_on_email", if_exists: true
    remove_index :subscriptions, name: "index_subscriptions_on_paddle_customer_id", if_exists: true
  end
end
