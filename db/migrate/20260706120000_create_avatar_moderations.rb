class CreateAvatarModerations < ActiveRecord::Migration[8.2]
  def change
    create_table :avatar_moderations do |t|
      t.references :blog, null: false, foreign_key: true, index: { unique: true }
      t.integer :status, null: false, default: 0
      t.jsonb :flags, default: {}
      t.jsonb :category_scores, default: {}
      t.string :fingerprint
      t.string :model_version
      t.datetime :moderated_at
      t.datetime :reviewed_at

      t.timestamps
    end

    add_index :avatar_moderations, :status
  end
end
