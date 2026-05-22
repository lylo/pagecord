class AddLocaleToPosts < ActiveRecord::Migration[8.2]
  def change
    add_column :posts, :locale, :string
    add_index :posts, :locale
  end
end
