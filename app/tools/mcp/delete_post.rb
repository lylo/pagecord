class Mcp::DeletePost < Mcp::Tool
  tool_name "delete_post"
  description "Move a post to the trash. It can be restored from the Pagecord app."
  input_schema(properties: { token: { type: "string" } }, required: [ "token" ])
  annotations(destructive_hint: true, idempotent_hint: true)

  def self.perform(blog, token:)
    find_post(blog, token).discard!
    { deleted: token }
  end
end
