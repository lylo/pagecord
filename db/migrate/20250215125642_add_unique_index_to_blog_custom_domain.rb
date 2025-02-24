class AddUniqueIndexToBlogCustomDomain < ActiveRecord::Migration[8.1]
  def change
    add_index :blogs, :custom_domain, unique: true, where: "custom_domain IS NOT NULL"
  end
end
