class CreateCancellations < ActiveRecord::Migration[8.2]
  def change
    create_table :cancellations do |t|
      t.references :user
      t.string :kind, null: false
      t.string :reason, null: false
      t.text :feedback
      t.string :plan
      t.timestamps
    end
  end
end
