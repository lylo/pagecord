class App::Blogs::AvatarsController < App::BaseController
  def destroy
    @blog.avatar.purge
    @blog.touch

    redirect_to app_settings_about_index_path, notice: "Avatar removed"
  end
end
