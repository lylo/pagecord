class CreateCustomDomainChanges < ActiveRecord::Migration[7.2]
  def change
    create_table :custom_domain_changes do |t|
      t.references :user, null: false, foreign_key: true
      t.string :custom_domain

      t.timestamps
    end
  end
end
