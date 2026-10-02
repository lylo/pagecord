class AddPaddleStatusToSubscriptions < ActiveRecord::Migration[8.2]
  def change
    add_column :subscriptions, :paddle_status, :string
  end
end
