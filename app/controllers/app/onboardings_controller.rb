class App::OnboardingsController < AppController
  skip_before_action :onboarding_check

  def show
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

  def complete
    Current.user.onboarding_complete!

    redirect_to app_root_path, notice: "Welcome to Pagecord!"
  end

  private

    def blog_params
      params.require(:blog).permit(:bio, :title, :layout, :theme, :width, :font, :locale)
    end
end
