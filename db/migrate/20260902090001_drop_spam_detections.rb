class DropSpamDetections < ActiveRecord::Migration[8.2]
  def up
    drop_table :spam_detections
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
