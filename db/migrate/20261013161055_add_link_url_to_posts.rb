class AddLinkUrlToPosts < ActiveRecord::Migration[8.2]
  def change
    add_column :posts, :link_url, :string
  end
end
