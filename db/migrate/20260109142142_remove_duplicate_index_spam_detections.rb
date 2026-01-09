class RemoveDuplicateIndexSpamDetections < ActiveRecord::Migration[8.2]
  def change
    remove_index :spam_detections, name: "index_spam_detections_on_blog_id", column: :blog_id
  end
end
