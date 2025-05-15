class AddShowUpvotesFlagToBlog < ActiveRecord::Migration[8.1]
  def change
    add_column :blogs, :show_upvotes, :boolean, default: true, null: false
  end
end
