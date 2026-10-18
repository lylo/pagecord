env "FEATURE"

# Connecting Claude, ChatGPT and other MCP clients to a blog.
feature :mcp do |user: nil, blog: nil|
  (user || blog&.user)&.features&.include?("mcp")
end
