class AddTitleToUser < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :title, :string
  end
end
