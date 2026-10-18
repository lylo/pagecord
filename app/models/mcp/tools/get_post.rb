class Mcp::Tools::GetPost < Mcp::Tool
  describe "Fetch one post, with its content as Markdown.",
    properties: { token: { type: "string" } }, required: %i[ token ], read_only: true

  def self.perform(blog, token:)
    post = find_post(blog, token)
    summarize(post).merge(content: ReverseMarkdown.convert(post.content.body.to_html, github_flavored: true))
  end
end
