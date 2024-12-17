class Blogs::SitemapsController < Blogs::BaseController
  def show
    fresh_when(
      etag: @blog.posts.maximum(:updated_at),
      last_modified: @blog.posts.maximum(:updated_at),
      public: true)
  end
end
