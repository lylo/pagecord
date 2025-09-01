class RemoveIpAddressAndCountryFromPageViews < ActiveRecord::Migration[8.1]
  def change
    remove_column :page_views, :ip_address, :string
    remove_column :page_views, :country, :string
  end
end
