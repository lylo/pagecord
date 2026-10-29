class Mcp::Tools::CreatePost < Mcp::Tool
  describe "Create a post. It is saved as a draft unless status is published.",
    properties: POST_PROPERTIES, required: %i[ content ], destructive: false

  def self.perform(blog, **arguments)
    summarize blog.posts.create!(post_attributes(arguments.reverse_merge(status: "draft")).merge(source: :api))
  end
end
