class RemoveFeaturesFromBlogs < ActiveRecord::Migration[8.2]
  def up
    remove_column :blogs, :features if column_exists?(:blogs, :features)
  end

  def down
    add_column :blogs, :features, :string, array: true, default: [] unless column_exists?(:blogs, :features)
  end
end
