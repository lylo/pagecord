class Mcp::Tools::GetPost < Mcp::Tool
  describe "Fetch one post, with its content as Markdown and its images, each with a public URL, filename, size and alt text. " \
    "Images and files appear in the content as <action-text-attachment> tags; keep them as they are when updating the post, " \
    "or they are removed. Use set_image_alt to change an image's alt text.",
    properties: { token: { type: "string" } }, required: %i[ token ], read_only: true

  def self.perform(blog, token:)
    post = find_post(blog, token)

    summarize(post).merge(
      content: ReverseMarkdown.convert(post.content.body.to_html, github_flavored: true),
      images: image_attachments(post.content.body.fragment).map do |node, blob|
        { url: rails_public_blob_url(blob), filename: blob.filename.to_s, width: node["width"]&.to_i, height: node["height"]&.to_i, alt: node["alt"].to_s }
      end
    )
  end
end
