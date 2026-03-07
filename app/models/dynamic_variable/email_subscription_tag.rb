class DynamicVariable::EmailSubscriptionTag
  def initialize(blog:, view:, params_string:)
    @view = view
  end

  def render
    @view.render(partial: "blogs/email_subscriber_form")
  end
end
