class DynamicVariable::ContactFormTag
  def initialize(blog:, view:, params_string:)
    @blog = blog
    @view = view
  end

  def render
    return "" unless @blog.contactable?

    @view.render(partial: "blogs/contact_messages/form")
  end
end
