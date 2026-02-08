class Posts::EmptyTrashJob < ApplicationJob
  queue_as :default

  def perform
    count = Post.discarded.where("discarded_at < ?", 30.days.ago).destroy_all.count
    Rails.logger.info "Emptied #{count} #{"post".pluralize(count)} from trash"
  end
end
