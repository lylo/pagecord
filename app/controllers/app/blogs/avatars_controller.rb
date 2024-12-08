class App::Blogs::AvatarsController < AppController
  def destroy
    @blog.avatar.purge
    redirect_to app_settings_blogs_path
  end
end
