class RemoveUnusedIndexes < ActiveRecord::Migration[8.1]
  def change
    remove_index :email_subscribers, name: "index_email_subscribers_on_blog_id"
    remove_index :posts, name: "index_posts_on_blog_id"
    remove_index :subscription_renewal_reminders, name: "index_subscription_renewal_reminders_on_subscription_id"
    remove_index :upvotes, name: "index_upvotes_on_post_id"
    remove_index :pages, name: "index_pages_on_blog_id"
  end
end
