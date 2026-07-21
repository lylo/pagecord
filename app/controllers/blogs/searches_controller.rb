class Blogs::SearchesController < Blogs::BaseController
  include Pagy::Method

  PAGE_SIZE = 25
  MAX_QUERY_LENGTH = 100

  rate_limit to: 30, within: 1.minute

  def show
    @query = params[:q].to_s.strip.first(MAX_QUERY_LENGTH)
    return if @query.blank?

    scope = @blog.all_posts.visible.for_blog_render
      .order(Arel.sql("CASE WHEN posts.is_page THEN posts.updated_at ELSE posts.published_at END DESC"))

    scope = if @query.match?(/^".*"$/)
      scope.search_exact_phrase(@query.gsub(/^"|"$/, ""))
    else
      scope.search_by_title_and_content(@query)
    end

    @pagy, @posts = pagy(scope, limit: PAGE_SIZE)
  end
end
