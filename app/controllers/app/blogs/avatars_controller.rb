class App::Blogs::AvatarsController < AppController
  def destroy
    @blog.avatar.purge
    @blog.posts.touch_all

    redirect_to app_settings_blogs_path
  end
end
