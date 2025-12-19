class DropFollowings < ActiveRecord::Migration[8.2]
  def change
    drop_table :followings do |t|
      t.bigint :followed_id
      t.bigint :follower_id
      t.timestamps
      t.index [ :follower_id, :followed_id ], unique: true
    end
  end
end
