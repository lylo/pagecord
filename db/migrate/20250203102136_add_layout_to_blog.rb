class AddLayoutToBlog < ActiveRecord::Migration[8.1]
  def change
    add_column :blogs, :layout, :integer, default: 0
  end
end
