class Admin::Moderation::Blogs::SpamConfirmationsController < Admin::BaseController
  def create
    blog = Blog.kept.find(params[:blog_id])

    blog.touch(:reviewed_at)
    DestroyUserJob.perform_later(blog.user.id, reason: :spam)

    redirect_back fallback_location: admin_moderation_blogs_path, notice: "@#{blog.subdomain} confirmed as spam and the user will be discarded"
  end
end
