class Admin::Moderation::Blogs::ReviewsController < Admin::BaseController
  def create
    blog = Blog.kept.reviewable.find(params[:blog_id])
    blog.touch(:reviewed_at) unless blog.reviewed_at?

    redirect_back fallback_location: admin_moderation_blogs_path, notice: "@#{blog.subdomain} marked as not spam"
  end
end
