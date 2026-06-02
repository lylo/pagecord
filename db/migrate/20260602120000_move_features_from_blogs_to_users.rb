class MoveFeaturesFromBlogsToUsers < ActiveRecord::Migration[8.2]
  def change
    add_column :users, :features, :string, array: true, default: [], null: false
    remove_column :blogs, :features, :string, array: true, default: [], null: false
  end
end
