class Mcp::ListPosts < Mcp::Tool
  PER_PAGE = 20

  tool_name "list_posts"
  description "List the blog's posts, newest first, #{PER_PAGE} at a time. Published includes scheduled posts."
  input_schema(
    properties: {
      status: { type: "string", enum: %w[ published draft ], default: "published" },
      page: { type: "integer", minimum: 1, default: 1 }
    }
  )
  annotations(read_only_hint: true)

  def self.perform(blog, status: "published", page: 1)
    posts = blog.posts.kept.public_send(status)

    {
      posts: posts.order(published_at: :desc, id: :desc).limit(PER_PAGE).offset((page - 1) * PER_PAGE).map { post_summary(it) },
      page: page,
      total: posts.count
    }
  end
end
