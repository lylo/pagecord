class AddDeliveryEmailToUser < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :delivery_email, :string
    add_index :users, :delivery_email, unique: true
  end
end
