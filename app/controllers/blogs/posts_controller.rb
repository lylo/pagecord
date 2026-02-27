class Blogs::PostsController < Blogs::BaseController
  include Pagy::Method, RequestHash, PostsHelper

  rate_limit to: 60, within: 1.minute

  skip_forgery_protection only: :not_found
  rescue_from Pagy::RangeError, with: :redirect_to_last_page

  def index
    # FIXME this filtered check can be removed after cache has been reset
    filtered = params[:tag].present?
    if request.format.html? && @blog.has_custom_home_page? && !filtered
      @post = @blog.home_page
      if @post&.published? && !@post.pending?
        set_blog_cache_headers
        return if fresh_when etag: etag_for(@post), last_modified: @post.updated_at, public: true, template: "blogs/posts/show"
        return render :show
      end
    end

    posts_list
  end

  def posts_list
    base_scope = @blog.posts.visible
      .with_full_rich_text
      .includes(:upvotes)
      .order(published_at: :desc, id: :desc)

    # Filter by tag if specified
    if params[:tag].present?
      base_scope = base_scope.tagged_with(params[:tag])
      @current_tag = params[:tag]
    end

    @pagy, @posts = pagy(base_scope, limit: page_size)

    respond_to do |format|
      format.html do
        return unless set_conditional_get_headers
        render :index
      end
      format.rss {
        return unless set_conditional_get_headers
        expires_in 5.minutes, public: true
        render :index, layout: false
      }
    end
  end

  # Shows a single post or page by its slug.
  def show
    @post = @blog.all_posts
      .kept
      .published
      .released
      .with_full_rich_text
      .includes(:upvotes)
      .find_by!(slug: blog_params[:slug])

    set_blog_cache_headers
    fresh_when etag: etag_for(@post), last_modified: @post.updated_at, public: true, template: "blogs/posts/show"
  end

  # Handle unmatched routes on blog domains
  def not_found
    raise ActiveRecord::RecordNotFound
  end

  private

    def redirect_to_last_page(exception)
      redirect_to url_for(page: exception.pagy.last, host: request.host)
    end

    def page_size
      @blog.title_layout? ? 100 : 15
    end

    def etag_for(post)
      post.is_page? ? [ post, @blog.posts.maximum(:updated_at) ] : post
    end

    def set_conditional_get_headers
      set_blog_cache_headers

      stale?(
        etag: [ @posts.map(&:id), @blog.id, @pagy.page ],
        last_modified: @posts.maximum(:updated_at),
        public: true
      )
    end

    # Enable Cloudflare edge caching for blog pages. Sets a 12-hour edge TTL
    # with tag-based purging (on post save / blog settings change). Skips the
    # session cookie so Cloudflare doesn't BYPASS the cache. Works for both
    # *.pagecord.com subdomains and custom domains routed via Cloudflare for SaaS
    # (DNS → domains.pagecord.com). No-op unless Cloudflare credentials are configured.
    def set_blog_cache_headers
      return unless Rails.env.production? && ENV["CLOUDFLARE_ZONE_ID"].present? && ENV["CLOUDFLARE_API_TOKEN"].present?

      response.headers["Cache-Tag"] = @blog.subdomain
      request.session_options[:skip] = true
      expires_in 0, public: true, "s-maxage": 12.hours.to_i, "stale-while-revalidate": 1.hour.to_i
    end
end
