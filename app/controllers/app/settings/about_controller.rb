class App::Settings::AboutController < App::BaseController
  include EditorContentSecurityPolicy

  # The editor previews embeds, which are third-party iframes
  editor_content_security_policy only: %i[ show update ]

  def show
  end

  def update
    if @blog.update(about_params)
      redirect_to app_settings_path, notice: "About settings updated"
    else
      # Discard the rejected upload so the form renders the existing avatar
      @blog.attachment_changes.delete("avatar")
      render :show, status: :unprocessable_entity
    end
  end

  private

    def about_params
      params.require(:blog).permit(:bio, :title, :avatar)
    end
end
