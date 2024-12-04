class RemoveBlogFieldsFromUser < ActiveRecord::Migration[8.1]
  def change
    remove_column :users, :title, :string
    remove_column :users, :custom_domain, :string
    remove_column :users, :delivery_email, :string
    remove_column :users, :bio_text, :text
  end
end
