class AddMarketingConsentToUser < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :marketing_consent, :boolean, null: false, default: false
  end
end
