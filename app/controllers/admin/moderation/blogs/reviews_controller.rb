class Admin::Moderation::Blogs::ReviewsController < Admin::BaseController
  def create
    blog = Blog.kept.find(params[:blog_id])
    blog.touch(:reviewed_at)

    redirect_back fallback_location: admin_moderation_blogs_path, notice: "@#{blog.subdomain} marked as reviewed"
  end
end
