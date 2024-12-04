class RemoveUserIdFromPost < ActiveRecord::Migration[8.1]
  def change
    remove_reference :posts, :user, foreign_key: true
  end
end
