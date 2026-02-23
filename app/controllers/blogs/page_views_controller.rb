class Blogs::PageViewsController < Blogs::BaseController
  skip_forgery_protection
  rate_limit to: 30, within: 1.minute, only: :create

  def create
    return head :no_content if params[:referrer]&.match?(%r{pagecord\.com/app})
    return head :no_content if Current.user == @blog.user
    return head :no_content if PageView.bot_user_agent?(request.user_agent)

    TrackPageViewJob.perform_later(
      @blog.id,
      params[:post_token],
      request.remote_ip,
      request.user_agent,
      params[:path],
      params[:referrer],
      request.headers["CF-IPCountry"]
    )

    head :no_content
  end
end
