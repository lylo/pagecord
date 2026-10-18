class Mcp::Tools::SetImageAlt < Mcp::Tool
  describe "Set the alt text of an image in a post, leaving the rest of the post as it is. url is the image's url from get_post. " \
    "Describe what the image shows, including any text in it, such as an event's date and place.",
    properties: {
      token: { type: "string" },
      url: { type: "string" },
      alt: { type: "string", description: "Empty removes the alt text." }
    },
    required: %i[ token url alt ], idempotent: true

  def self.perform(blog, token:, url:, alt:)
    post = find_post(blog, token)
    blob = Mcp::Tools::GetImage.find_image(blog, url)
    fragment = post.content.body.fragment

    node, _blob = image_attachments(fragment).find { |_node, attached| attached == blob }
    raise Api::BadRequestError, "That image isn't in this post" unless node

    alt.present? ? node["alt"] = alt : node.remove_attribute("alt")
    post.update!(content: fragment.to_html)

    summarize(post).merge(image_url: rails_public_blob_url(blob), alt: alt)
  end
end
