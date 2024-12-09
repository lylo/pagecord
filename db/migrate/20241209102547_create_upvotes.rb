class CreateUpvotes < ActiveRecord::Migration[8.1]
  def change
    create_table :upvotes do |t|
      t.references :post, null: false, foreign_key: true
      t.string :hash_id, null: false
      t.timestamps

      t.index [ :post_id, :hash_id ], unique: true
    end
  end
end
