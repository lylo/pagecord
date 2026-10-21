class Admin::Moderation::Blogs::RemovalsController < Admin::BaseController
  def create
    blog = Blog.kept.find(params[:blog_id])

    blog.touch(:reviewed_at)
    DestroyUserJob.perform_later(blog.user.id, reason: :admin_deleted)

    redirect_back fallback_location: admin_moderation_blogs_path, notice: "@#{blog.subdomain} removed"
  end
end
