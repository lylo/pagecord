class AddEmailDeliveryModeToBlogs < ActiveRecord::Migration[8.2]
  def change
    add_column :blogs, :email_delivery_mode, :integer, default: 0, null: false
  end
end
