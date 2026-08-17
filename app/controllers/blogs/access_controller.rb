class Blogs::AccessController < Blogs::BaseController
  ACCESS_DURATION = 30.days

  skip_before_action :require_blog_access
  rate_limit to: 10, within: 1.minute, only: :create

  def create
    if @blog.password_protected? && @blog.authenticate(params[:password])
      cookies.encrypted[ACCESS_COOKIE] = {
        value: @blog.password_digest,
        expires: ACCESS_DURATION,
        httponly: true,
        secure: Rails.application.config.force_ssl
      }
      redirect_to safe_return_to
    else
      redirect_to safe_return_to, alert: t("private_blog.incorrect")
    end
  end

  private

    # Browsers read both "//host" and "/\host" as scheme-relative, so an
    # open redirect needs only the leading slash to look local.
    def safe_return_to
      path = params[:return_to].to_s
      path.match?(/\A\/($|[^\/\\])/) ? path : root_path
    end
end
