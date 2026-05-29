class App::Settings::AppearanceController < AppController
  def index
  end

  def update
    if @blog.update(appearance_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to app_settings_path, notice: "Appearance settings updated" }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update("css-error", @blog.errors[:custom_css].first.to_s),
            turbo_stream.update("footer-error", @blog.errors[:custom_footer_html].first.to_s)
          ],
                 status: :unprocessable_entity
        end
        format.html { render :index, status: :unprocessable_entity }
      end
    end
  end

  private

    def appearance_params
      permitted_params = [
        :layout, :theme, :font, :width,
        :custom_theme_bg_light, :custom_theme_text_light, :custom_theme_accent_light,
        :custom_theme_bg_dark, :custom_theme_text_dark, :custom_theme_accent_dark
      ]

      permitted_params << :show_branding if @blog.user.subscribed?
      permitted_params += [ :custom_css, :custom_footer_html ] if @blog.user.has_premium_access?

      params.require(:blog).permit(permitted_params)
    end
end
