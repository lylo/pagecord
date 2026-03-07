class DynamicVariable::PostsByYearTag
  include DynamicVariable::Params

  def initialize(blog:, view:, params_string:)
    @blog = blog
    @view = view
    @params = parse_params(params_string)
  end

  def render
    order_direction = @params[:sort] == "asc" ? :asc : :desc
    posts = @blog.posts.visible
      .apply_filters(**filter_args)
      .order(published_at: order_direction)
      .all
    @view.render(partial: "blogs/custom_tags/posts_by_year", locals: { posts: posts })
  end

  private

    def filter_args
      {}.tap do |args|
        args[:tag] = @params[:tag] if @params[:tag]
        args[:without_tag] = @params[:without_tag] if @params[:without_tag]
        args[:title] = @params[:title] if @params.key?(:title)
        args[:emailed] = @params[:emailed] if @params.key?(:emailed)
        args[:lang] = @params[:lang] if @params[:lang]
        args[:blog_locale] = @blog.locale if @params[:lang]
      end
    end
end
