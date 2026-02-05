class AddExcludeFromDigestToPosts < ActiveRecord::Migration[8.2]
  def change
    add_column :posts, :exclude_from_digest, :boolean, default: false, null: false
  end
end
