class AddVerifiedToUser < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :verified, :boolean, default: false
  end
end
