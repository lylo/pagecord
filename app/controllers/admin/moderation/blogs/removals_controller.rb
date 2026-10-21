class Admin::Moderation::Blogs::RemovalsController < Admin::BaseController
  include Admin::Moderation::Queue

  def create
    blog = Blog.kept.find(params[:blog_id])

    blog.touch(:reviewed_at)
    DestroyUserJob.perform_later(blog.user.id, reason: :admin_deleted)

    respond_reviewed blog, "@#{blog.subdomain} removed"
  end
end
