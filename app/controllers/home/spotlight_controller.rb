class Home::SpotlightController < ApplicationController
  CACHE_DURATION = 15.minutes
  ELIGIBILITY_DELAY = 15.minutes

  include RoutingHelper
  layout "home"
  before_action -> { redirect_to root_path unless Current.user&.admin? } # TODO: remove before launch

  def show
    @tab = params[:tab] == "recent" ? "recent" : "trending"

    @posts = @tab == "recent" ? recent_posts : trending_posts
  end

  private

    def recent_posts
      Rails.cache.fetch("public_spotlight_recent_posts", expires_in: CACHE_DURATION) do
        spotlight_posts_scope
          .where("published_at <= ?", spotlight_cutoff_time)
          .order(published_at: :desc)
          .limit(20)
          .includes(:blog)
      end
    end

    def trending_posts
      Rails.cache.fetch("public_spotlight_trending_posts", expires_in: CACHE_DURATION) do
        # Delay Spotlight eligibility briefly so new posts have a short privacy buffer.
        Analytics::Trending.new.top_posts(limit: 100)
          .select { |item| item[:post].published_at <= spotlight_cutoff_time }
          .first(20)
      end
    end

    def spotlight_posts_scope
      Post.visible.posts
        .joins(blog: :user)
        .where(blogs: { allow_search_indexing: true })
        .where(users: { discarded_at: nil })
    end

    def spotlight_cutoff_time
      ELIGIBILITY_DELAY.ago
    end
end
