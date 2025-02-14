class Blogs::PostsController < Blogs::BaseController
  include Pagy::Backend, RequestHash, PostsHelper

  rescue_from Pagy::OverflowError, with: :redirect_to_last_page

  def index
    @posts = @blog.posts.published
      .with_rich_text_content_and_embeds
      .order(published_at: :desc)

    @pagy, @posts = pagy(@posts, limit: page_size)

    respond_to do |format|
      format.html
      format.rss { render layout: false }
    end
  end

  def show
    @post = @blog.posts.published
      .with_rich_text_content_and_embeds
      .find_by!(token: blog_params[:token])

    fresh_when @post, public: true, template: "blogs/posts/show"
  end

  private

    def redirect_to_last_page(exception)
      redirect_to url_for(page: exception.pagy.last)
    end

    def page_size
      @blog.stream_layout? ? 15 : 100
    end
end
