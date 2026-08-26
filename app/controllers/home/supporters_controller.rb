class Home::SupportersController < ApplicationController
  include PubliclyCached

  layout "home"

  CACHE_TTL = 15.minutes

  before_action :set_cache_headers

  def show
    @blogs = supporter_blogs
  end

  private

    def set_cache_headers
      cache_publicly(maxage: CACHE_TTL, stale: 1.minute)
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
