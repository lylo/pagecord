class Blogs::PageViewsController < Blogs::BaseController
  skip_before_action :verify_authenticity_token

  def create
    post = @blog.all_posts.published.released.find_by(token: params[:post_token]) if params[:post_token].present?

    PageView.track(blog: @blog, post: post, request: request, path: params[:path])

    head :no_content
  rescue => e
    Rails.logger.error "Analytics error: #{e.message}\n#{e.backtrace.take(5).join("\n")}"
    Sentry.capture_message("Analytics error: #{e.message}")
    head :no_content
  end
end
