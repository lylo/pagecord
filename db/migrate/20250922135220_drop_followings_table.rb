class DropFollowingsTable < ActiveRecord::Migration[8.1]
  def change
    drop_table :followings
  end
end
