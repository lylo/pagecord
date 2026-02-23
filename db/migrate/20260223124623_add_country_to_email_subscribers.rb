class AddCountryToEmailSubscribers < ActiveRecord::Migration[8.2]
  def change
    add_column :email_subscribers, :country, :string
  end
end
