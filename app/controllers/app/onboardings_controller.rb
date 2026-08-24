class App::OnboardingsController < App::BaseController
  skip_before_action :onboarding_check

  def show
    @featured_templates = ThemeTemplate.active.ordered.limit(6)
  end

  def update
    if @blog.update(blog_params)
      respond_to do |format|
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("bio_error", partial: "bio_error"), status: :unprocessable_entity
        end
      end
    end
  end

  private

    def blog_params
      params.require(:blog).permit(:bio, :title, :layout, :theme, :width, :font, :locale)
    end
end
