class CreatePaddleEvents < ActiveRecord::Migration[7.2]
  def change
    create_table :paddle_events do |t|
      t.references :user, null: false, foreign_key: true
      t.jsonb :payload

      t.timestamps
    end
  end
end
