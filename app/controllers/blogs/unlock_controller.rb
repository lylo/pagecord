class Blogs::UnlockController < Blogs::BaseController
  UNLOCK_DURATION = 30.days

  skip_before_action :require_blog_password
  rate_limit to: 10, within: 1.minute, only: :create

  # Both outcomes go back where the visitor started, so the gate is the only
  # thing they ever see at their own URL and /unlock never reaches the address
  # bar.
  def create
    if @blog.password_protected? && @blog.authenticate(params[:password])
      cookies.encrypted[:blog_unlock] = { value: @blog.password_digest, expires: UNLOCK_DURATION, httponly: true }
      redirect_to safe_return_to
    else
      redirect_to safe_return_to, alert: t("unlock.incorrect")
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
