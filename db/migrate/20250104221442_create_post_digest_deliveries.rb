class CreatePostDigestDeliveries < ActiveRecord::Migration[8.1]
  def change
    create_table :post_digest_deliveries do |t|
      t.references :post_digest, null: false, foreign_key: true
      t.references :email_subscriber, null: false, foreign_key: true
      t.datetime :delivered_at

      t.timestamps
    end
  end
end
