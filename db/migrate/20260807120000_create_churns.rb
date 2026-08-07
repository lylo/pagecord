class CreateChurns < ActiveRecord::Migration[8.2]
  def change
    create_table :churns do |t|
      # Deliberately no foreign key and no inverse association on User: this row
      # must outlive the account it describes, including the nightly purge.
      t.bigint :user_id
      t.string :kind, null: false
      t.datetime :occurred_at, null: false
      t.string :plan
      t.integer :unit_price
      t.string :paddle_subscription_id
      t.string :blog_subdomain
      t.string :signup_referrer
      t.datetime :signed_up_at
      t.datetime :subscribed_at
      t.integer :posts_count

      t.timestamps
    end

    add_index :churns, :occurred_at
    add_index :churns, :user_id
    add_index :churns, [ :kind, :paddle_subscription_id ], unique: true
  end
end
