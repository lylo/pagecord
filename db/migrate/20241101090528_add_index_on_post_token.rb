class AddIndexOnPostToken < ActiveRecord::Migration[8.0]
  def change
    add_index :posts, :token, unique: true
  end
end
