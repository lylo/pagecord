class StandardSite::SyncDocumentJob < ApplicationJob
  discard_on ActiveRecord::RecordNotFound

  def perform(post_id)
    post = Post.find(post_id)
    return unless post.blog.standard_site_account&.connected?

    document = post.standard_site_document || post.create_standard_site_document!
    document.sync!
  end
end
