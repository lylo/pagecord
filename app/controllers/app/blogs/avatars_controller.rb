class App::Blogs::AvatarsController < AppController
  def destroy
    @blog.avatar.purge
    @blog.posts.touch_all

    redirect_to app_settings_appearance_index_path, notice: "Avatar removed"
  end
end
