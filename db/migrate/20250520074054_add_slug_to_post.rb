class AddSlugToPost < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :slug, :string

    add_index :posts, [ :blog_id, :slug ], unique: true
  end
end
