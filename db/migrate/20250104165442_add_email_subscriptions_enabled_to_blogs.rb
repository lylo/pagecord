class AddEmailSubscriptionsEnabledToBlogs < ActiveRecord::Migration[8.1]
  def change
    add_column :blogs, :email_subscriptions_enabled, :boolean, default: true, null: false
  end
end
