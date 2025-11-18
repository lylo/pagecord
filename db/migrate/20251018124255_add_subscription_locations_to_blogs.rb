class AddSubscriptionLocationsToBlogs < ActiveRecord::Migration[8.1]
  def change
    add_column :blogs, :show_subscription_in_header, :boolean, default: true, null: false
    add_column :blogs, :show_subscription_in_footer, :boolean, default: true, null: false
  end
end
