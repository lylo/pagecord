class PurgeCloudflareCacheJob < ApplicationJob
  queue_as :default

  discard_on ActiveRecord::RecordNotFound
  retry_on StandardError, wait: :polynomially_longer, attempts: 5

  def perform(blog_id)
    blog = Blog.find(blog_id)
    CloudflareCacheApi.new.purge_blog(blog)
  end
end
