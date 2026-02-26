class CreateUnengagedFollowUps < ActiveRecord::Migration[8.1]
  def change
    create_table :unengaged_follow_ups do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.datetime :sent_at, null: false
      t.timestamps
    end
  end
end
