class App::Blogs::RestorationsController < AppController
  before_action :require_multiple_blogs

  def create
    blog = Current.user.all_blogs.discarded.find(params[:blog_id])

    if Current.user.blogs.count >= Current.user.blog_limit
      redirect_to app_blogs_trash_path, alert: "You can't restore this blog because you've already reached your blog limit"
    else
      blog.undiscard!
      redirect_to app_blogs_trash_path, notice: "#{blog.display_name} was successfully restored"
    end
  end

  private

    def require_multiple_blogs
      redirect_to app_root_path unless current_features.enabled?(:multiple_blogs)
    end
end
