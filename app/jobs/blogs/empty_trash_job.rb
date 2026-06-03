class Blogs::EmptyTrashJob < ApplicationJob
  queue_as :default

  def perform
    count = Blog.discarded.where("discarded_at < ?", 30.days.ago).destroy_all.count
    Rails.logger.info "Emptied #{count} #{"blog".pluralize(count)} from trash"
  end
end
