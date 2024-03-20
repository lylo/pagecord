class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :username, null: false

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :username, unique: true
  end
end
