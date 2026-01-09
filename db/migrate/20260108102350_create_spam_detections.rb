class CreateSpamDetections < ActiveRecord::Migration[8.2]
  def change
    create_table :spam_detections do |t|
      t.references :blog, null: false, foreign_key: true
      t.integer :status, default: 0, null: false
      t.text :reason
      t.datetime :detected_at
      t.string :model_version
      t.datetime :reviewed_at

      t.timestamps
    end

    add_index :spam_detections, :status
    add_index :spam_detections, [ :blog_id, :detected_at ], order: { detected_at: :desc }
  end
end
