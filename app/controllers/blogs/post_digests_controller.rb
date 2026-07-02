class Blogs::PostDigestsController < Blogs::BaseController
  def show
    digest = PostDigest.find_by_masked_id(params[:masked_id])
    @digest = @blog.post_digests.find(digest&.id)
    @posts = @digest.posts.visible.for_blog_render.ordered_by_published

    set_blog_cache_headers
    fresh_when etag: [ @digest.id, @blog.updated_at ], last_modified: @blog.updated_at, public: true
  end
end
