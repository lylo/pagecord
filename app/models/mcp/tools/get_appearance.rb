class Mcp::Tools::GetAppearance < Mcp::Tool
  describe "Get the blog's theme, font, width, layout and custom colours, and its public URL.", read_only: true

  def self.perform(blog)
    blog.as_json(only: Themeable::ATTRIBUTES).merge(url: blog_home_url(blog))
  end
end
