# Shows a draft or scheduled post to anyone holding its signed link.
class Blogs::Posts::PreviewsController < Blogs::BaseController
  include RoutingHelper

  rate_limit to: 60, within: 1.minute

  def show
    @post = @blog.all_posts.kept.for_blog_render.find_signed(params[:id], purpose: :preview) or raise ActiveRecord::RecordNotFound
    return redirect_to post_path(@post) if @post.published? && !@post.pending?

    no_store
  end
end
