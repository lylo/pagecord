class DynamicVariable::TagsTag
  include DynamicVariable::Params

  def initialize(blog:, view:, params_string:)
    @blog = blog
    @view = view
    @params = parse_params(params_string)
  end

  def render
    tags = @blog.posts.visible.all_tags
    partial = @params[:style] == "inline" ? "blogs/custom_tags/tags_inline" : "blogs/custom_tags/tags"
    @view.render(partial: partial, locals: { tags: tags, blog: @blog })
  end
end
