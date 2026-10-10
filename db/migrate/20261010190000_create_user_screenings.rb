class CreateUserScreenings < ActiveRecord::Migration[8.2]
  def change
    create_table :user_screenings do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.jsonb :failed_checks, null: false, default: {}
      t.timestamps
    end
  end
end
