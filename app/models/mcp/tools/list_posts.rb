class Mcp::Tools::ListPosts < Mcp::Tool
  PER_PAGE = 20

  describe "List the blog's posts, newest first, #{PER_PAGE} at a time. Published includes scheduled posts.",
    properties: {
      status: { type: "string", enum: %w[ published draft ], default: "published" },
      page: { type: "integer", minimum: 1, default: 1 }
    },
    read_only: true

  def self.perform(blog, status: "published", page: 1)
    posts = status == "draft" ? blog.posts.kept.draft : blog.posts.kept.published
    page = page.to_i.clamp(1..)

    {
      posts: posts.order(published_at: :desc, id: :desc).limit(PER_PAGE).offset(PER_PAGE * (page - 1)).map { summarize(it) },
      page: page,
      total: posts.count
    }
  end
end
