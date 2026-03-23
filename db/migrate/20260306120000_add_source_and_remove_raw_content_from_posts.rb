class AddSourceAndRemoveRawContentFromPosts < ActiveRecord::Migration[8.2]
  def change
    add_column :posts, :source, :integer, default: 0, null: false

    reversible do |dir|
      dir.up do
        execute "UPDATE posts SET source = 1 WHERE raw_content IS NOT NULL"
      end
    end

    remove_column :posts, :raw_content, :text
  end
end
