class Blogs::PostsController < Blogs::BaseController
  include Pagy::Backend, RequestHash, PostsHelper

  rescue_from Pagy::OverflowError, with: :redirect_to_last_page

  def index
    @pagy, @posts = pagy(@blog.posts.includes(:rich_text_content).order(published_at: :desc))

    respond_to do |format|
      format.html
      format.rss { render layout: false }
    end
  end

  def show
    @post = @blog.posts.find_by!(token: blog_params[:token])

    fresh_when @post, public: true, template: "blogs/posts/post"
  end

  private

    def redirect_to_last_page(exception)
      redirect_to url_for(page: exception.pagy.last)
    end
end
