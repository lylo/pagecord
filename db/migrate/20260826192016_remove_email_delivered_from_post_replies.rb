class RemoveEmailDeliveredFromPostReplies < ActiveRecord::Migration[8.2]
  def change
    # Written by nothing and read by nothing: replies are destroyed as soon as
    # the email is sent. The guard is because the column only ever existed in
    # schema-loaded databases: the 2025 commit that introduced it put it in
    # schema.rb without a migration, so production never had it.
    if column_exists?(:post_replies, :email_delivered)
      remove_column :post_replies, :email_delivered, :boolean, default: false, null: false
    end
  end
end
