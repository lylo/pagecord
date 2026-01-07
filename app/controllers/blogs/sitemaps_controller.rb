class Blogs::SitemapsController < Blogs::BaseController
  rate_limit to: 60, within: 1.minute

  def show
    fresh_when(
      etag: @blog.posts.kept.maximum(:updated_at),
      last_modified: @blog.posts.kept.maximum(:updated_at),
      public: true
    )

    respond_to do |format|
      format.xml # Render the default XML template (e.g., show.xml.builder)
      format.any { head :not_acceptable } # Return 406 for unsupported formats
    end
  end
end
