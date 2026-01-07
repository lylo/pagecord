class CreateContentModerations < ActiveRecord::Migration[8.2]
  def change
    create_table :content_moderations do |t|
      t.references :post, null: false, foreign_key: true, index: { unique: true }
      t.integer :status, default: 0, null: false
      t.jsonb :flags, default: {}
      t.datetime :moderated_at
      t.string :fingerprint
      t.string :model_version

      t.timestamps
    end

    add_index :content_moderations, :status
  end
end
