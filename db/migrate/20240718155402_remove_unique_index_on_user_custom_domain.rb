class RemoveUniqueIndexOnUserCustomDomain < ActiveRecord::Migration[8.0]
  def change
    remove_index :users, :custom_domain, unique: true
    add_index :users, :custom_domain
  end
end
