class AddTagListToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :tag_list, :string, array: true, default: []
    add_index :posts, :tag_list, using: :gin
  end
end
