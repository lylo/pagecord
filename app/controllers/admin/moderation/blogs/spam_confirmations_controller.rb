class Admin::Moderation::Blogs::SpamConfirmationsController < Admin::BaseController
  include Admin::Moderation::Queue

  def create
    blog = Blog.kept.find(params[:blog_id])

    blog.touch(:reviewed_at)
    DestroyUserJob.perform_later(blog.user.id, reason: :spam)

    respond_reviewed blog, "@#{blog.subdomain} confirmed as spam and the user will be discarded"
  end
end
