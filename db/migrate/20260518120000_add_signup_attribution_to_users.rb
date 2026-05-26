class AddSignupAttributionToUsers < ActiveRecord::Migration[8.2]
  def change
    add_column :users, :signup_referrer, :string
    add_column :users, :signup_source_note, :string, limit: 500
  end
end
