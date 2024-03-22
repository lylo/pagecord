class AddBioToUser < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :bio, :text
  end
end
