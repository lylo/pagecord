class CreateEmailSuppressions < ActiveRecord::Migration[8.2]
  def change
    create_table :email_suppressions do |t|
      t.string :email, null: false
      t.string :reason, null: false
      t.string :bounce_type
      t.string :diagnostic_code
      t.datetime :suppressed_at, null: false
      t.timestamps
    end
    add_index :email_suppressions, :email, unique: true
  end
end
