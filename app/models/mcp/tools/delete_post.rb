class Mcp::Tools::DeletePost < Mcp::Tool
  describe "Move a post to the trash. It can be restored from the Pagecord app.",
    properties: { token: { type: "string" } }, required: %i[ token ], destructive: true

  def self.perform(blog, token:)
    find_post(blog, token).discard!
    { deleted: token }
  end
end
