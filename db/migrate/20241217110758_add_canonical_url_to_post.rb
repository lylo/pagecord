class AddCanonicalUrlToPost < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :canonical_url, :string
  end
end
