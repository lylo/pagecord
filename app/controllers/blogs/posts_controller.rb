class Blogs::PostsController < Blogs::BaseController
  include Pagy::Backend, RequestHash, PostsHelper

  rate_limit to: 60, within: 1.minute

  skip_before_action :verify_authenticity_token, only: :not_found
  before_action :show_homepage_if_set, only: :index
  rescue_from Pagy::OverflowError, with: :redirect_to_last_page
  rescue_from Pagy::VariableError, with: :redirect_to_first_page

  def index
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
        set_conditional_get_headers
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
      .published
      .released
      .with_full_rich_text
      .includes(:upvotes)
      .find_by!(slug: blog_params[:slug])

    fresh_when @post, public: true, template: "blogs/posts/show"
  end

  # Handle unmatched routes on blog domains
  def not_found
    raise ActiveRecord::RecordNotFound
  end

  private

    def show_homepage_if_set
      return unless @blog.home_page_id.present? && request.format.html?

      @post = @blog.home_page
      return unless @post&.published? && !@post.pending?

      fresh_when @post, public: true, template: "blogs/posts/show"
      render "blogs/posts/show"
    end

    def redirect_to_last_page(exception)
      redirect_to url_for(page: exception.pagy.last, host: request.host)
    end

    def redirect_to_first_page
      redirect_to url_for(page: 1, host: request.host)
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
