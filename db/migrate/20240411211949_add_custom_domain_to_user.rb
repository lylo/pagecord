class AddCustomDomainToUser < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :custom_domain, :string
    add_index :users, :custom_domain, unique: true
  end
end
