class CreateDigestPosts < ActiveRecord::Migration[8.1]
  def change
    create_table :digest_posts do |t|
      t.references :post_digest, null: false, foreign_key: true
      t.references :post, null: false, foreign_key: true

      t.timestamps
    end
  end
end
