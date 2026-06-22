class Home::SpotlightController < ApplicationController
  include RoutingHelper
  layout "home"

  CACHE_TTL = 15.minutes

  before_action :set_spotlight_cache_headers

  def show
    return unless stale?(etag: spotlight_etag, public: true)

    respond_to do |format|
      format.html do
        @tab = selected_tab
        @posts = spotlight_items
      end
      format.rss do
        @posts = feed_posts
        render :show, layout: false
      end
    end
  end

  private

    def selected_tab
      @selected_tab ||= params[:tab] == "recent" ? "recent" : "trending"
    end

    def feed_posts
      # Trending stores score hashes; RSS needs render-ready posts with rich text loaded.
      posts = spotlight_items.map { |item| item[:post] }
      posts_by_id = Post.where(id: posts.map(&:id)).for_blog_render.includes(:blog).index_by(&:id)

      posts.filter_map { |post| posts_by_id[post.id] }
    end

    def spotlight_refresh_window
      Time.current.to_i / CACHE_TTL.to_i
    end

    def spotlight_etag
      [ "spotlight", selected_tab, request.format.symbol, spotlight_refresh_window ]
    end

    def set_spotlight_cache_headers
      request.session_options[:skip] = true
      expires_in 0, public: true, "s-maxage": CACHE_TTL.to_i, "stale-while-revalidate": 1.minute.to_i
    end

    def spotlight_items
      Rails.cache.fetch([ "public_spotlight", selected_tab ], expires_in: CACHE_TTL, race_condition_ttl: 10.seconds) do
        selected_tab == "recent" ? recent_posts : trending_posts
      end
    end

    def recent_posts
      latest_per_blog = spotlight_posts_scope
        .where(published_at: ..15.minutes.ago)
        .where("posts.locale = 'en' OR (posts.locale IS NULL AND blogs.locale = 'en')")
        .select("DISTINCT ON (posts.blog_id) posts.*")
        .order("posts.blog_id, posts.published_at DESC")

      Post.from(latest_per_blog, :posts)
        .order(published_at: :desc)
        .limit(20)
        .includes(:blog)
        .to_a
    end

    def trending_posts
      # Delay Spotlight eligibility briefly so new posts have a short privacy buffer.
      Analytics::Trending.new.top_posts(limit: 100)
        .select { |item| item[:post].published_at <= 15.minutes.ago }
        .first(20)
    end

    def spotlight_posts_scope
      Post.visible.posts.joins(:blog).merge(Blog.spotlit)
    end
end
