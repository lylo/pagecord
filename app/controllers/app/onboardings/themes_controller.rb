class App::Onboardings::ThemesController < App::BaseController
  skip_before_action :onboarding_check

  def update
    @blog.update(appearance_attributes)

    head :no_content
  end

  private

    def appearance_attributes
      template = ThemeTemplate.active.find(params[:template_id]) if params[:template_id].present?

      Blog.column_defaults.slice("custom_css", "theme_template_id", "theme_template_version", *Themeable::ATTRIBUTES.map(&:to_s)).merge(template&.appearance_attributes.to_h)
    end
end
