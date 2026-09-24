class Mcp::GetPost < Mcp::Tool
  tool_name "get_post"
  description "Fetch one post, with its content as Markdown."
  input_schema(properties: { token: { type: "string" } }, required: [ "token" ])
  annotations(read_only_hint: true)

  def self.perform(blog, token:)
    post = find_post(blog, token)
    post_summary(post).merge(content: ReverseMarkdown.convert(post.content.body.to_html, github_flavored: true))
  end
end
