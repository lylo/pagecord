class CreatePostComments < ActiveRecord::Migration[8.2]
  def change
    create_table :post_comments do |t|
      t.references :post, null: false, foreign_key: true
      t.references :parent, foreign_key: { to_table: :post_comments }
      t.string :name, null: false
      t.string :link
      t.text :message, null: false
      t.datetime :approved_at
      t.boolean :author, null: false, default: false

      t.timestamps
    end

    add_index :post_comments, [ :post_id, :approved_at ]
    add_index :post_comments, :parent_id, unique: true, where: "author", name: "index_post_comments_on_author_reply_parent_id"

    add_column :posts, :comments_count, :integer, null: false, default: 0
    add_column :posts, :comments_closed_at, :datetime
    add_column :blogs, :comments_enabled, :boolean, null: false, default: false
  end
end
