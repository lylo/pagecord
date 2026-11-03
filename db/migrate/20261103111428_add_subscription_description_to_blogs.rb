class AddSubscriptionDescriptionToBlogs < ActiveRecord::Migration[8.2]
  def change
    add_column :blogs, :subscription_description, :string
  end
end
