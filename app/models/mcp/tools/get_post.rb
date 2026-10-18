class Mcp::Tools::GetPost < Mcp::Tool
  describe "Fetch one post, with its content as Markdown and a public URL for each image in it.",
    properties: { token: { type: "string" } }, required: %i[ token ], read_only: true

  def self.perform(blog, token:)
    post = find_post(blog, token)

    summarize(post).merge(
      content: ReverseMarkdown.convert(post.content.body.to_html, github_flavored: true),
      images: post.content.body.attachables.grep(ActiveStorage::Blob).select(&:image?).map { rails_public_blob_url(it) }
    )
  end
end
