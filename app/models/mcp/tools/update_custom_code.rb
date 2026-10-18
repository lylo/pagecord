class Mcp::Tools::UpdateCustomCode < Mcp::Tool
  LIMITS = { custom_css: Css::Sanitizer::MAX_CSS_SIZE, custom_footer_html: Blog::CustomFooter::MAX_SIZE, **Blog::CustomCode::MAX_SIZES }.freeze

  describe "Change the blog's custom CSS, footer HTML, and head and body HTML. Only the fields given change; each replaces the whole value. " \
    "Returns which fields changed and each field's size against its limit. With dry_run, nothing is saved and validation errors are reported the same way.",
    properties: {
      custom_css: { type: "string", description: "Up to #{LIMITS[:custom_css] / 1.kilobyte}KB." },
      custom_footer_html: { type: "string", description: "Shown beneath every page. Up to #{LIMITS[:custom_footer_html] / 1.kilobyte}KB." },
      custom_head_html: { type: "string", description: "Subscribers only. Up to #{LIMITS[:custom_head_html] / 1.kilobyte}KB of head elements such as script, style, link and meta." },
      custom_body_html: { type: "string", description: "Subscribers only. Up to #{LIMITS[:custom_body_html] / 1.kilobyte}KB, inserted at the end of the body." },
      custom_code_enabled: { type: "boolean", description: "Subscribers only. Whether the head and body HTML are used." },
      dry_run: { type: "boolean", description: "Validate without saving." }
    },
    idempotent: true

  def self.perform(blog, dry_run: false, **arguments)
    forbidden = Blog::CustomCode::SUBSCRIBER_ATTRIBUTES.find { arguments.key?(it) } unless blog.user.subscribed?
    raise Api::ForbiddenError, "#{forbidden} requires a subscription" if forbidden

    blog.assign_attributes(arguments)
    changed = blog.changed
    dry_run ? blog.validate! : blog.save!

    {
      saved: !dry_run,
      changed: changed,
      sizes: LIMITS.to_h { |field, limit| [ field, { bytes: blog[field].to_s.bytesize, limit: limit } ] }
    }
  end
end
