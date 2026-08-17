class Home::SupportersController < ApplicationController
  layout "home"

  CACHE_TTL = 15.minutes

  before_action :set_cache_headers

  def show
    @blogs = supporter_blogs
  end

  private

    def set_cache_headers
      request.session_options[:skip] = true
      expires_in 0, public: true, "s-maxage": CACHE_TTL.to_i, "stale-while-revalidate": 1.minute.to_i
    end

    def supporter_blogs
      # One blog per supporter, preferring the one with a custom domain.
      blog_per_supporter = Blog.kept
        .joins(user: :subscription)
        .merge(User.kept.where(admin: false))
        .merge(Subscription.active_paid.supporter)
        .select("DISTINCT ON (blogs.user_id) blogs.*")
        .order(Arel.sql("blogs.user_id, (COALESCE(blogs.custom_domain, '') = ''), blogs.created_at"))

      Blog.from(blog_per_supporter, :blogs).order(Arel.sql("RANDOM()")).includes(avatar_attachment: :blob)
    end
end
