class Mcp::UpdatePost < Mcp::Tool
  tool_name "update_post"
  description "Update a post. Only the fields given change; content replaces the whole body."
  input_schema(properties: POST_PROPERTIES.merge(token: { type: "string" }), required: [ "token" ])
  annotations(idempotent_hint: true)

  def self.perform(blog, token:, **arguments)
    post_summary find_post(blog, token).tap { it.update!(post_attributes(arguments)) }
  end
end
