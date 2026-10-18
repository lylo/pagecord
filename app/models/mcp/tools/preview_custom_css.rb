class Mcp::Tools::PreviewCustomCss < Mcp::Tool
  describe "Get a link that shows the blog's home page with this CSS instead of the saved custom CSS, without saving it. " \
    "The link works for #{Blog::CustomCode::CSS_PREVIEW_LIFETIME.inspect} and anyone with it can open it. CSS that wouldn't save is refused with the reasons.",
    properties: { custom_css: { type: "string" } }, required: %i[ custom_css ], read_only: true

  def self.perform(blog, custom_css:)
    blog.custom_css = custom_css
    blog.validate
    raise Api::BadRequestError, blog.errors.full_messages_for(:custom_css).join("\n") if blog.errors.include?(:custom_css)

    { url: blog_css_preview_url(blog.stash_css_preview(custom_css), host: blog.host) }
  end
end
