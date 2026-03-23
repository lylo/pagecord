class CreateContactMessages < ActiveRecord::Migration[8.2]
  def change
    create_table :contact_messages do |t|
      t.references :blog, null: false, foreign_key: true
      t.string :name, null: false
      t.string :email, null: false
      t.text :message, null: false

      t.timestamps
    end
  end
end
