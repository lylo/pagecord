# Stashes unsaved custom CSS and sends the tab to the blog, which renders it.
class App::Settings::CustomCode::PreviewsController < App::BaseController
  skip_before_action :onboarding_check

  def update
    token = SecureRandom.base58(24)
    css = Css::Sanitizer.sanitize_stylesheet(params[:blog][:custom_css].to_s)
    Rails.cache.write("css_preview:#{@blog.id}:#{token}", css, expires_in: 10.minutes)

    redirect_to blog_css_preview_url(token, host: @blog.host), allow_other_host: true
  end
end
