class Blogs::PostsController < Blogs::BaseController
  include Pagy::Method, RequestHash, PostsHelper

  rate_limit to: 60, within: 1.minute

  skip_forgery_protection only: :not_found
  rescue_from Pagy::RangeError, with: :redirect_to_last_page

  def index
    if request.format.html? && @blog.has_custom_home_page? && !filtered?
      @post = @blog.home_page
      if @post&.published? && !@post.pending?
        set_blog_cache_headers
        return if fresh_when etag: [ @post.id, @blog.updated_at ], last_modified: @blog.updated_at, public: true, template: "blogs/posts/show"
        return render :show
      end
    end

    posts_list
  end

  def posts_list
    @current_tags = params[:tag].split(",").map(&:strip) if params[:tag].present?
    @current_lang = params[:lang].to_s.downcase.split("-").first if params[:lang].present?

    scope = @blog.posts.visible
      .for_blog_render
      .ordered_by_published
    scope = scope.tagged_with_any(@current_tags) if @current_tags
    scope = scope.tagged_without_any(params[:without_tag].split(",").map(&:strip)) if params[:without_tag].present?
    scope = scope.titled(params[:title]) if params[:title].present?
    scope = scope.for_locale(@current_lang, @blog.locale) if @current_lang

    @pagy, @posts = pagy(scope, limit: page_size)

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
      .for_blog_render
      .find_by!(slug: blog_params[:slug])

    return if flash.any? # Don't cache responses with flash — session skip prevents flash clearing

    set_blog_cache_headers
    fresh_when etag: [ @post.id, @blog.updated_at ], last_modified: @blog.updated_at, public: true
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

    def set_conditional_get_headers
      set_blog_cache_headers

      stale?(
        etag: [ @blog.id, @blog.updated_at, @pagy.page ],
        last_modified: @blog.updated_at,
        public: true
      )
    end
end
