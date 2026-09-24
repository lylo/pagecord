class Mcp::CreatePost < Mcp::Tool
  tool_name "create_post"
  description "Create a post. It is saved as a draft unless status is published."
  input_schema(properties: POST_PROPERTIES, required: [ "content" ])

  def self.perform(blog, **arguments)
    post_summary blog.posts.create!(post_attributes(arguments.reverse_merge(status: "draft")).merge(source: :api))
  end
end
