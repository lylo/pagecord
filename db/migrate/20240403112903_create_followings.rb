class CreateFollowings < ActiveRecord::Migration[7.2]
  def change
    create_table :followings do |t|
      t.bigint :follower_id
      t.bigint :followed_id

      t.timestamps
    end

    add_index :followings, [:follower_id, :followed_id], unique: true
  end
end
