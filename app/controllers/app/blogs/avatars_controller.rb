class App::Blogs::AvatarsController < AppController
  def destroy
    @blog.avatar.purge
    @blog.touch

    redirect_to app_settings_about_index_path, notice: "Avatar removed"
  end
end
