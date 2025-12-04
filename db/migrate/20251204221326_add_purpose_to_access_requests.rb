class AddPurposeToAccessRequests < ActiveRecord::Migration[8.2]
  def change
    add_column :access_requests, :purpose, :string, default: "login", null: false
  end
end
