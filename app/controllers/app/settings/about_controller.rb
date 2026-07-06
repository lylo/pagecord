class App::Settings::AboutController < AppController
  def index
  end

  def update
    if @blog.update(about_params)
      AvatarModerationJob.perform_later(@blog.id) if params.dig(:blog, :avatar).present?
      redirect_to app_settings_path, notice: "About settings updated"
    else
      render :index, status: :unprocessable_entity
    end
  end

  private

    def about_params
      params.require(:blog).permit(:bio, :title, :avatar)
    end
end
