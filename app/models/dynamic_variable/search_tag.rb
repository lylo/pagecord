class DynamicVariable::SearchTag
  def initialize(blog:, view:, params_string:)
    @view = view
  end

  def render
    @view.render(partial: "blogs/searches/form")
  end
end
