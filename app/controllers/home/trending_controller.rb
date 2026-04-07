class Home::TrendingController < ApplicationController
  include RoutingHelper
  layout "home"
  before_action -> { redirect_to root_path unless Current.user&.admin? } # TODO: remove before launch

  def show
    @tab = params[:tab] == "recent" ? "recent" : "trending"

    @posts = if @tab == "recent"
      Rails.cache.fetch("public_recent_posts", expires_in: 1.hour) do
        Post.visible.posts
          .joins(blog: :user)
          .where(blogs: { allow_search_indexing: true })
          .where(users: { discarded_at: nil })
          .order(published_at: :desc)
          .limit(20)
          .includes(:blog)
      end
    else
      Rails.cache.fetch("public_trending_posts", expires_in: 1.day) do
        Analytics::Trending.new.top_posts(limit: 20)
      end
    end
  end
end
