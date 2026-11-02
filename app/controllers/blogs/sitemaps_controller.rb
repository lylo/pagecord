class Blogs::SitemapsController < Blogs::BaseController
  rate_limit to: 60, within: 1.minute

  def show
    fresh_when(
      etag: @blog.all_posts.kept.maximum(:updated_at),
      last_modified: @blog.all_posts.kept.maximum(:updated_at),
      public: true
    )
  end
end
