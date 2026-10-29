class Mcp::Tools::UpdatePost < Mcp::Tool
  describe "Update a post. Only the fields given change; content replaces the whole body.",
    properties: POST_PROPERTIES.merge(token: { type: "string" }), required: %i[ token ], idempotent: true, destructive: true

  def self.perform(blog, token:, **arguments)
    summarize find_post(blog, token).tap { it.update!(post_attributes(arguments)) }
  end
end
