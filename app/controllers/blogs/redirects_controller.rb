class Blogs::RedirectsController < Blogs::BaseController
  def show
    raise ActiveRecord::RecordNotFound unless custom_domain_request?

    post = @blog.posts
      .kept
      .published
      .released
      .find_by!(slug: blog_params[:slug])

    redirect_to "/#{post.slug}", status: :moved_permanently
  end
end
