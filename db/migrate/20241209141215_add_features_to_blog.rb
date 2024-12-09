class AddFeaturesToBlog < ActiveRecord::Migration[8.1]
  def change
    add_column :blogs, :features, :string, array: true, default: []
  end
end
