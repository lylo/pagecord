class CascadeDeleteSpamDetections < ActiveRecord::Migration[8.2]
  def up
    remove_foreign_key :spam_detections, :blogs
    add_foreign_key :spam_detections, :blogs, on_delete: :cascade
  end

  def down
    remove_foreign_key :spam_detections, :blogs
    add_foreign_key :spam_detections, :blogs
  end
end
