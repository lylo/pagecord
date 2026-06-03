class StandardSite::SyncPublicationJob < ApplicationJob
  discard_on ActiveRecord::RecordNotFound

  def perform(blog_id)
    blog = Blog.find(blog_id)
    return unless blog.standard_site_account&.connected?

    publication = blog.standard_site_publication || blog.create_standard_site_publication!
    publication.sync!

    if publication.synced?
      blog.all_posts.visible.find_each do |post|
        StandardSite::SyncDocumentJob.perform_later(post.id)
      end
    end
  end
end
