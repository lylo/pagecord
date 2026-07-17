class App::Settings::AboutController < AppController
  def index
  end

  def update
    if @blog.update(about_params)
      redirect_to app_settings_path, notice: "About settings updated"
    else
      # Discard the rejected upload so the form renders the existing avatar
      @blog.attachment_changes.delete("avatar")
      render :index, status: :unprocessable_entity
    end
  end

  private

    def about_params
      params.require(:blog).permit(:bio, :title, :avatar)
    end
end
