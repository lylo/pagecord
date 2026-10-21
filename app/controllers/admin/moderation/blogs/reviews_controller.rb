class Admin::Moderation::Blogs::ReviewsController < Admin::BaseController
  include Admin::Moderation::Queue

  def create
    blog = Blog.kept.find(params[:blog_id])
    blog.touch(:reviewed_at)

    respond_reviewed blog, "@#{blog.subdomain} marked as not spam"
  end
end
