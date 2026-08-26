class RemoveEmailDeliveredFromPostReplies < ActiveRecord::Migration[8.2]
  def change
    # Written by nothing and read by nothing: replies are destroyed as soon as
    # the email is sent.
    remove_column :post_replies, :email_delivered, :boolean, default: false, null: false
  end
end
