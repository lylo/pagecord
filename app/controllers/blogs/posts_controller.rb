class Blogs::PostsController < Blogs::BaseController
  include Pagy::Backend, RequestHash, PostsHelper

  rescue_from Pagy::OverflowError, with: :redirect_to_last_page

  def index
    @posts = @blog.posts.visible
      .with_rich_text_content_and_embeds
      .includes(
        :upvotes,
        rich_text_content: { embeds_attachments: :blob }
      )
      .order(published_at: :desc)

    @pagy, @posts = pagy(@posts, limit: page_size)

    respond_to do |format|
      format.html { set_conditional_get_headers }
      format.rss {
        return unless set_conditional_get_headers
        render layout: false
      }
    end
  end

  # Shows a single post or page by its slug.
  def show
    @post = @blog.all_posts.visible
      .with_rich_text_content_and_embeds
      .includes(rich_text_content: { embeds_attachments: :blob })
      .find_by!(slug: blog_params[:slug])

    fresh_when @post, public: true, template: "blogs/posts/show"
  end

  private

    def redirect_to_last_page(exception)
      redirect_to url_for(page: exception.pagy.last, host: request.host)
    end

    def page_size
      @blog.stream_layout? ? 15 : 100
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
