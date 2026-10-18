class Mcp::Tools::GetPost < Mcp::Tool
  describe "Fetch one post, with its content as Markdown and a public URL for each image in it. Images and files appear in " \
    "the content as <action-text-attachment> tags; keep them as they are when updating the post, or they are removed.",
    properties: { token: { type: "string" } }, required: %i[ token ], read_only: true

  def self.perform(blog, token:)
    post = find_post(blog, token)

    summarize(post).merge(
      content: ReverseMarkdown.convert(post.content.body.to_html, github_flavored: true),
      images: attached_blobs(post).select(&:image?).map { rails_public_blob_url(it) }
    )
  end

  class << self
    private
      # Located in one query, where Action Text's attachables resolves one blob per attachment.
      def attached_blobs(post)
        sgids = post.content.body.fragment.find_all("action-text-attachment[sgid]").map { it["sgid"] }
        GlobalID::Locator.locate_many_signed(sgids, for: ActionText::Attachable::LOCATOR_NAME, ignore_missing: true).grep(ActiveStorage::Blob)
      end
  end
end
