class RemoveUnneededIndexes < ActiveRecord::Migration[8.1]
  def change
    remove_index :sender_email_addresses, name: "index_sender_email_addresses_on_blog_id", column: :blog_id
  end
end
