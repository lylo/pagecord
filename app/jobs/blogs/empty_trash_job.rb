class Blogs::EmptyTrashJob < ApplicationJob
  queue_as :default

  def perform
    blog_ids = Blog.discarded.where("discarded_at < ?", 30.days.ago).ids
    blog_ids.each { Blogs::DestroyJob.perform_later(it) }

    Rails.logger.info "Queued #{blog_ids.size} #{"blog".pluralize(blog_ids.size)} for deletion"
  end
end
