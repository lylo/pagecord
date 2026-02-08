class Posts::EmptyTrashJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "Emptying post trash (deleting posts discarded > 30 days ago)"
    count = Post.discarded
                .where("discarded_at < ?", 30.days.ago)
                .destroy_all
                .count
    Rails.logger.info "Deleted #{count} posts from trash"
  end
end
