class App::Onboardings::CompletionsController < App::BaseController
  skip_before_action :onboarding_check

  def create
    if @blog.update(blog_params)
      Current.user.onboarding_complete!
      redirect_to app_posts_path
    else
      @templates = ThemeTemplate.offered_to(@blog).ordered
      render "app/onboardings/show", layout: "letter", status: :unprocessable_entity
    end
  end

  private

    def blog_params
      params.require(:blog).permit(:bio, :locale).tap do |blog|
        blog[:bio] = ERB::Util.html_escape(blog[:bio]).gsub("\n", "<br>") if blog.key?(:bio)
      end
    end
end
