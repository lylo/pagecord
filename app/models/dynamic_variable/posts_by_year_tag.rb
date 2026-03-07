class DynamicVariable::PostsByYearTag
  def initialize(blog:, view:, params_string:)
    @blog = blog
    @view = view
    @post_list_params = DynamicVariable::PostListParams.new(blog: @blog, params_string: params_string)
  end

  def render
    posts = @blog.posts.visible
      .filtered_for_dynamic_variable(**@post_list_params.filter_args(include_year: false))
      .all
    @view.render(partial: "blogs/custom_tags/posts_by_year", locals: { posts: posts })
  end
end
