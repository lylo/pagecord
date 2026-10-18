# Stashes unsaved custom CSS and sends the tab to the blog, which renders it.
class App::Settings::CustomCode::PreviewsController < App::BaseController
  skip_before_action :onboarding_check
  before_action :require_premium

  def update
    css = params[:blog][:custom_css].to_s
    return head :content_too_large if css.bytesize > Css::Sanitizer::MAX_CSS_SIZE

    token = SecureRandom.base58(24)
    Rails.cache.write("css_preview:#{@blog.id}:#{token}", Css::Sanitizer.sanitize_stylesheet(css), expires_in: 10.minutes)

    redirect_to blog_css_preview_url(token, host: @blog.host), allow_other_host: true
  end

  private

    def require_premium
      render_app_not_found unless Current.user.has_premium_access?
    end
end
