class AddNotificationsEmailAddressToBlogs < ActiveRecord::Migration[8.2]
  def change
    add_reference :blogs, :notifications_email_address, foreign_key: { to_table: :sender_email_addresses, on_delete: :nullify }
  end
end
