class Blogs::PostsController < Blogs::BaseController
  include Pagy::Backend, RequestHash, PostsHelper

  rate_limit to: 60, within: 1.minute

  rescue_from Pagy::OverflowError, with: :redirect_to_last_page

  def index
    base_scope = @blog.posts.visible
      .with_full_rich_text
      .includes(:upvotes)
      .order(published_at: :desc)

    # Filter by tag if specified
    if params[:tag].present?
      base_scope = base_scope.tagged_with(params[:tag])
      @current_tag = params[:tag]
    end

    @pagy, @posts = pagy(base_scope, limit: page_size)

    respond_to do |format|
      format.html { set_conditional_get_headers }
      format.rss {
        return unless set_conditional_get_headers
        expires_in 5.minutes, public: true
        render layout: false
      }
    end
  end

  # Shows a single post or page by its slug.
  def show
    @post = @blog.all_posts
      .published
      .released
      .with_full_rich_text
      .includes(:upvotes)
      .find_by!(slug: blog_params[:slug])

    fresh_when @post, public: true, template: "blogs/posts/show"
  end

  private

    def redirect_to_last_page(exception)
      redirect_to url_for(page: exception.pagy.last, host: request.host)
    end

    def page_size
      @blog.title_layout? ? 100 : 15
    end

    def set_conditional_get_headers
      if stale?(
        etag: [ @posts.map(&:id), @blog.id, @pagy.page ],
        last_modified: @posts.maximum(:updated_at),
        public: true
      )
        true
      else
        false
      end
    end
end
