class Home::SpotlightController < ApplicationController
  include RoutingHelper
  layout "home"

  def show
    @tab = params[:tab] == "recent" ? "recent" : "trending"

    @posts = @tab == "recent" ? recent_posts : trending_posts
  end

  private

    def recent_posts
      Rails.cache.fetch("public_spotlight_recent_posts", expires_in: 15.minutes) do
        spotlight_posts_scope
          .where(published_at: ..15.minutes.ago)
          .where("posts.locale = 'en' OR (posts.locale IS NULL AND blogs.locale = 'en')")
          .order(published_at: :desc)
          .limit(20)
          .includes(:blog)
          .to_a
      end
    end

    def trending_posts
      Rails.cache.fetch("public_spotlight_trending_posts", expires_in: 15.minutes) do
        # Delay Spotlight eligibility briefly so new posts have a short privacy buffer.
        Analytics::Trending.new.top_posts(limit: 100)
          .select { |item| item[:post].published_at <= 15.minutes.ago }
          .first(20)
      end
    end

    def spotlight_posts_scope
      Post.visible.posts
        .joins(blog: :user)
        .where(blogs: { allow_search_indexing: true })
        .where(users: { discarded_at: nil })
    end
end
