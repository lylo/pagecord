class Mcp::Tools::UpdateCustomCode < Mcp::Tool
  describe "Change the blog's custom CSS, footer HTML, and head and body HTML. Only the fields given change; each replaces the whole value.",
    properties: {
      custom_css: { type: "string", description: "Up to #{Css::Sanitizer::MAX_CSS_SIZE / 1.kilobyte}KB." },
      custom_footer_html: { type: "string", description: "Shown beneath every page. Up to #{Blog::CustomFooter::MAX_SIZE / 1.kilobyte}KB." },
      custom_head_html: { type: "string", description: "Subscribers only. Up to #{Blog::CustomCode::MAX_SIZES[:custom_head_html] / 1.kilobyte}KB of head elements such as script, style, link and meta." },
      custom_body_html: { type: "string", description: "Subscribers only. Up to #{Blog::CustomCode::MAX_SIZES[:custom_body_html] / 1.kilobyte}KB, inserted at the end of the body." },
      custom_code_enabled: { type: "boolean", description: "Subscribers only. Whether the head and body HTML are used." }
    },
    idempotent: true

  def self.perform(blog, **arguments)
    forbidden = Blog::CustomCode::SUBSCRIBER_ATTRIBUTES.find { arguments.key?(it) } unless blog.user.subscribed?
    raise Api::ForbiddenError, "#{forbidden} requires a subscription" if forbidden

    blog.update!(arguments)
    blog.as_json(only: Mcp::Tools::GetCustomCode::FIELDS)
  end
end
