module Blogs::AccessControl
  extend ActiveSupport::Concern

  # Blog owners can run their own JavaScript on *.pagecord.com, so the __Host-
  # prefix is what stops one blog writing an access cookie that reaches another.
  # It demands the Secure flag, so plain-HTTP development keeps the bare name.
  ACCESS_COOKIE = Rails.application.config.force_ssl ? "__Host-blog_access" : "blog_access"

  private

    def require_blog_access
      render_private_blog_login unless blog_access_granted?
    end

    # A password protected blog is unlocked by storing its password digest in
    # the access cookie, or by a valid feed key.
    def blog_access_granted?
      return true unless @blog&.password_protected?

      cookies.encrypted[ACCESS_COOKIE] == @blog.password_digest || feed_key_request?
    end

    # Feed readers can't fill in the login form, so RSS is unlocked by a token
    # in the URL instead.
    def feed_key_request?
      request.format.rss? && @blog.valid_feed_token?(params[:key])
    end

    def render_private_blog_login
      if request.format.html?
        render "blogs/access/login", status: :unauthorized
      else
        head :unauthorized
      end
    end
end
