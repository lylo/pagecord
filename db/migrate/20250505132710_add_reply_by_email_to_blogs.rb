class AddReplyByEmailToBlogs < ActiveRecord::Migration[8.1]
  def change
    add_column :blogs, :reply_by_email, :boolean, default: false, null: false
  end
end
