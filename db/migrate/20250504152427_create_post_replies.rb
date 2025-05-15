class CreatePostReplies < ActiveRecord::Migration[7.1]
  def change
    create_table :post_replies do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :subject, null: false
      t.text :message, null: false
      t.references :post, null: false, foreign_key: true

      t.timestamps
    end

    add_index :post_replies, :email
    add_index :post_replies, :created_at
  end
end
