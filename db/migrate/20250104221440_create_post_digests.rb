class CreatePostDigests < ActiveRecord::Migration[8.1]
  def change
    create_table :post_digests do |t|
      t.references :blog, null: false, foreign_key: true
      t.datetime :delivered_at

      t.timestamps
    end
  end
end
